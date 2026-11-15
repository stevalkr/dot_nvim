#!/usr/bin/env python3
"""Neovim <-> Claude review bridge.

One process owns the Unix socket (``mcp`` or ``listen``); Neovim and short-lived
CLI calls (``reply``, ``qf``, ``comments``, ``state``, ``status``) connect to it
as clients. Messages are newline-delimited JSON. Python stdlib only, 3.6+.
"""

import argparse
import errno
import fcntl
import json
import os
import signal
import socket
import sys
import threading
import time

PROTOCOL_VERSION = 1
SOCKET_ENV = 'CLAUDE_REVIEW_SOCK'
DEFAULT_RELATIVE = os.path.join('.cache', 'claude-review', 'bridge.sock')
REQUEST_TIMEOUT = 3.0
MCP_SERVER_VERSION = '0.1.0'
COMMENT_STATES = ('draft', 'sent', 'delivered', 'replied', 'resolved')


class BridgeError(Exception):
    pass


# --------------------------------------------------------------------------
# Socket paths and framing


def owner_socket_path(explicit=None):
    """The path an owner binds: --socket, then $CLAUDE_REVIEW_SOCK, then cwd."""
    path = explicit or os.environ.get(SOCKET_ENV)
    if path:
        return os.path.abspath(path)
    return os.path.join(os.getcwd(), DEFAULT_RELATIVE)


def client_socket_path(explicit=None):
    """Like owner_socket_path, but looks in parent directories for the default
    socket so a CLI call still finds it after a `cd` into the workspace."""
    path = explicit or os.environ.get(SOCKET_ENV)
    if path:
        return os.path.abspath(path)
    directory = os.getcwd()
    while True:
        candidate = os.path.join(directory, DEFAULT_RELATIVE)
        if os.path.exists(candidate):
            return candidate
        parent = os.path.dirname(directory)
        if parent == directory:
            return os.path.join(os.getcwd(), DEFAULT_RELATIVE)
        directory = parent


def encode(message):
    return (json.dumps(message, ensure_ascii=False) + '\n').encode('utf-8')


class LineReader(object):
    def __init__(self, sock):
        self.sock = sock
        self.buffer = b''

    def read(self):
        """Next decoded message, or None at EOF. Skips malformed lines."""
        while True:
            index = self.buffer.find(b'\n')
            if index >= 0:
                line, self.buffer = self.buffer[:index], self.buffer[index + 1:]
                if not line.strip():
                    continue
                try:
                    message = json.loads(line.decode('utf-8'))
                except ValueError:
                    continue
                if isinstance(message, dict):
                    return message
                continue
            try:
                chunk = self.sock.recv(65536)
            except OSError:
                return None
            if not chunk:
                return None
            self.buffer += chunk


class Connection(object):
    def __init__(self, sock):
        self.sock = sock
        self.reader = LineReader(sock)
        self.lock = threading.Lock()
        self.role = None
        self.closed = False

    def send(self, message):
        data = encode(message)
        with self.lock:
            if self.closed:
                return False
            try:
                self.sock.sendall(data)
                return True
            except OSError:
                return False

    def close(self):
        with self.lock:
            if self.closed:
                return
            self.closed = True
        try:
            self.sock.shutdown(socket.SHUT_RDWR)
        except OSError:
            pass
        self.sock.close()


# --------------------------------------------------------------------------
# Socket owner


class Owner(object):
    """Owns the socket, relays between Neovim and CLI clients, and hands
    comments to a mode-specific `deliver(comment) -> bool` callback."""

    def __init__(self, path, deliver, on_event=None):
        self.path = path
        self.deliver = deliver
        self.on_event = on_event or (lambda kind, detail=None: None)
        self.lock = threading.RLock()
        self.nvim = None
        self.outbox = []  # replies and quickfix lists waiting for Neovim
        self.comments = {}  # root id -> comment as delivered, with replies
        self.message_roots = {}  # message id -> root comment id
        self.pending = {}  # request id -> [event, response]
        self.next_request = 0
        self.server = None
        self.lock_file = None
        self.stopped = threading.Event()

    # -- lifetime ---------------------------------------------------------

    def bind(self):
        directory = os.path.dirname(self.path)
        try:
            os.makedirs(directory)
        except OSError as err:
            if err.errno != errno.EEXIST:
                raise BridgeError('cannot create {}: {}'.format(directory, err))
        # The lock decides ownership; the socket file may be a stale leftover.
        self.lock_file = open(self.path + '.lock', 'a')
        try:
            fcntl.flock(self.lock_file.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
        except OSError:
            self.lock_file.close()
            self.lock_file = None
            raise BridgeError(
                'another claude-review owner already holds {} '
                '(stop it first, or use --socket)'.format(self.path)
            )
        if os.path.exists(self.path) or os.path.islink(self.path):
            os.unlink(self.path)
        server = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        try:
            server.bind(self.path)
        except OSError as err:
            server.close()
            self.release()
            raise BridgeError('cannot bind {}: {}'.format(self.path, err))
        server.listen(8)
        self.server = server
        thread = threading.Thread(target=self.accept_loop)
        thread.daemon = True
        thread.start()

    def stop(self):
        if self.stopped.is_set():
            return
        self.stopped.set()
        if self.server is not None:
            try:
                self.server.close()
            except OSError:
                pass
            try:
                os.unlink(self.path)
            except OSError:
                pass
        with self.lock:
            nvim = self.nvim
            self.nvim = None
        if nvim is not None:
            nvim.close()
        self.release()

    def release(self):
        if self.lock_file is not None:
            self.lock_file.close()
            self.lock_file = None

    def accept_loop(self):
        while not self.stopped.is_set():
            try:
                sock, _ = self.server.accept()
            except OSError:
                return
            thread = threading.Thread(target=self.serve, args=(Connection(sock),))
            thread.daemon = True
            thread.start()

    # -- per connection ---------------------------------------------------

    def serve(self, conn):
        try:
            while True:
                message = conn.reader.read()
                if message is None:
                    break
                if not self.handle(conn, message):
                    break
        finally:
            self.drop(conn)

    def drop(self, conn):
        was_nvim = False
        with self.lock:
            if self.nvim is conn:
                self.nvim = None
                was_nvim = True
        conn.close()
        if was_nvim:
            self.on_event('nvim_disconnected')

    def handle(self, conn, message):
        kind = message.get('type')
        if kind == 'hello':
            conn.role = message.get('role')
            if conn.role == 'nvim':
                self.attach_nvim(conn)
            return True
        if conn.role == 'nvim':
            return self.handle_nvim(conn, message)
        if conn.role == 'cli':
            conn.send(self.handle_cli(message))
            return False
        conn.send({'type': 'error', 'message': 'send hello first'})
        return False

    def attach_nvim(self, conn):
        with self.lock:
            previous = self.nvim
            self.nvim = conn
            queued, self.outbox = self.outbox, []
        if previous is not None:
            previous.send({
                'type': 'error',
                'code': 'replaced',
                'message': 'another Neovim connected to this socket',
            })
            previous.close()
        self.on_event('nvim_connected')
        for item in queued:
            if not conn.send(item):
                with self.lock:
                    self.outbox.append(item)

    def handle_nvim(self, conn, message):
        kind = message.get('type')
        if kind == 'comment':
            self.receive_comment(conn, message)
        elif kind in ('state', 'comments'):
            self.resolve_request(message)
        elif kind == 'bye':
            self.on_event('nvim_bye')
            return False
        return True

    def receive_comment(self, conn, message):
        try:
            comment = normalize_comment(message)
        except BridgeError as err:
            conn.send({'type': 'error', 'message': str(err)})
            return
        with self.lock:
            # A resend after a lost ack: delivered already, only ack again.
            duplicate = comment['message_id'] in self.message_roots
        if not duplicate:
            if not self.deliver(comment):
                return
            with self.lock:
                self.message_roots[comment['message_id']] = comment['id']
                stored = self.comments.get(comment['id'])
                if stored is None or not comment['follow_up']:
                    stored = {
                        'id': comment['id'],
                        'path': comment['path'],
                        'start_line': comment['start_line'],
                        'end_line': comment['end_line'],
                        'text': comment['text'],
                        'state': 'delivered',
                        'thread': (stored or {}).get('thread', []),
                    }
                    self.comments[comment['id']] = stored
                else:
                    stored['thread'].append({'from': 'user', 'text': comment['text']})
                    stored['state'] = 'delivered'
                    stored['path'] = comment['path']
                    stored['start_line'] = comment['start_line']
                    stored['end_line'] = comment['end_line']
        conn.send({'type': 'ack', 'id': comment['message_id']})

    # -- requests to Neovim ------------------------------------------------

    def request_nvim(self, message, timeout=REQUEST_TIMEOUT):
        """Send a request to Neovim and wait for the response with the same
        req_id. Returns None if Neovim is absent or does not answer."""
        with self.lock:
            nvim = self.nvim
            if nvim is None:
                return None
            self.next_request += 1
            req_id = 'r{}'.format(self.next_request)
            slot = [threading.Event(), None]
            self.pending[req_id] = slot
        message = dict(message, req_id=req_id)
        try:
            if not nvim.send(message):
                return None
            slot[0].wait(timeout)
            return slot[1]
        finally:
            with self.lock:
                self.pending.pop(req_id, None)

    def resolve_request(self, message):
        with self.lock:
            slot = self.pending.get(message.get('req_id'))
        if slot is not None:
            slot[1] = message
            slot[0].set()

    # -- operations shared by CLI clients and MCP tools ----------------------

    def send_to_nvim(self, message):
        """Deliver now, or queue until Neovim (re)connects."""
        with self.lock:
            nvim = self.nvim
            if nvim is None:
                self.outbox.append(message)
                return 'queued'
        if nvim.send(message):
            return 'sent'
        with self.lock:
            self.outbox.append(message)
        return 'queued'

    def reply(self, comment_id, text, resolve=False):
        comment_id = str(comment_id or '').strip()
        if not comment_id:
            raise BridgeError('reply needs a comment id')
        if not isinstance(text, str) or not text.strip():
            raise BridgeError('reply needs text')
        with self.lock:
            root = self.message_roots.get(comment_id, comment_id)
            stored = self.comments.get(root)
            if stored is not None:
                stored['thread'].append({'from': 'claude', 'text': text})
                stored['state'] = 'resolved' if resolve else 'replied'
        return self.send_to_nvim({
            'type': 'reply',
            'comment_id': root,
            'text': text,
            'resolve': bool(resolve),
        })

    def quickfix(self, title, items, mode='replace'):
        if mode not in ('replace', 'append'):
            raise BridgeError('quickfix mode must be "replace" or "append"')
        return self.send_to_nvim({
            'type': 'quickfix',
            'title': title or 'Claude',
            'mode': mode,
            'items': normalize_items(items),
        })

    def list_comments(self, state=None):
        if state is not None and state not in COMMENT_STATES:
            raise BridgeError('unknown state: {}'.format(state))
        response = self.request_nvim({'type': 'comments_req', 'state': state})
        if response is not None and isinstance(response.get('items'), list):
            return {'source': 'nvim', 'items': response['items']}
        with self.lock:
            items = [dict(c, thread=list(c['thread'])) for c in self.comments.values()]
        if state is not None:
            items = [c for c in items if c['state'] == state]
        return {'source': 'bridge', 'items': items}

    def editor_state(self):
        response = self.request_nvim({'type': 'state_req'})
        if response is None:
            raise BridgeError('Neovim is not connected or did not answer')
        response = dict(response)
        response.pop('type', None)
        response.pop('req_id', None)
        return response

    def status(self):
        with self.lock:
            return {
                'socket': self.path,
                'pid': os.getpid(),
                'nvim_connected': self.nvim is not None,
                'queued': len(self.outbox),
                'comments_seen': len(self.comments),
            }

    def handle_cli(self, message):
        kind = message.get('type')
        try:
            if kind == 'reply':
                result = self.reply(
                    message.get('comment_id'), message.get('text'), message.get('resolve')
                )
            elif kind == 'quickfix':
                result = self.quickfix(
                    message.get('title'), message.get('items'), message.get('mode') or 'replace'
                )
            elif kind == 'comments_req':
                result = self.list_comments(message.get('state'))
            elif kind == 'state_req':
                result = self.editor_state()
            elif kind == 'status':
                result = self.status()
            else:
                raise BridgeError('unknown request: {}'.format(kind))
        except BridgeError as err:
            return {'type': 'error', 'message': str(err)}
        return {'type': 'result', 'result': result}


def as_line(value, name):
    try:
        line = int(value)
    except (TypeError, ValueError):
        raise BridgeError('{} must be a line number'.format(name))
    if line < 1:
        raise BridgeError('{} must be at least 1'.format(name))
    return line


def normalize_comment(message):
    message_id = str(message.get('id') or '').strip()
    if not message_id:
        raise BridgeError('comment without id')
    path = message.get('path')
    if not isinstance(path, str) or not path:
        raise BridgeError('comment {} without path'.format(message_id))
    start = as_line(message.get('start_line'), 'start_line')
    end = as_line(message.get('end_line', start), 'end_line')
    text = message.get('text')
    if not isinstance(text, str):
        raise BridgeError('comment {} without text'.format(message_id))
    thread_id = message.get('thread_id')
    return {
        'message_id': message_id,
        'id': str(thread_id) if thread_id else message_id,
        'follow_up': bool(thread_id),
        'path': path,
        'start_line': start,
        'end_line': max(start, end),
        'text': text,
    }


def normalize_items(items):
    if not isinstance(items, list):
        raise BridgeError('quickfix items must be a list')
    result = []
    for index, item in enumerate(items):
        if not isinstance(item, dict):
            raise BridgeError('quickfix item {} is not an object'.format(index + 1))
        path = item.get('path') or item.get('filename')
        if not isinstance(path, str) or not path:
            raise BridgeError('quickfix item {} has no path'.format(index + 1))
        entry = {
            'path': path,
            'lnum': as_line(item.get('lnum', item.get('line', 1)), 'lnum'),
            'text': str(item.get('text') or ''),
        }
        if item.get('end_lnum') is not None:
            entry['end_lnum'] = as_line(item['end_lnum'], 'end_lnum')
        if item.get('col') is not None:
            entry['col'] = as_line(item['col'], 'col')
        if item.get('type'):
            entry['type'] = str(item['type'])[:1].upper()
        result.append(entry)
    return result


def location(comment):
    if comment['start_line'] == comment['end_line']:
        return '{}:{}'.format(comment['path'], comment['start_line'])
    return '{}:{}-{}'.format(comment['path'], comment['start_line'], comment['end_line'])


def install_signal_handlers(owner):
    def handler(signum, frame):
        owner.stop()
        sys.exit(128 + signum)

    for signum in (signal.SIGTERM, signal.SIGHUP, signal.SIGINT):
        signal.signal(signum, handler)


# --------------------------------------------------------------------------
# listen: monitor mode


def write_stdout(text, lock):
    with lock:
        sys.stdout.write(text)
        sys.stdout.flush()


def cmd_listen(args):
    out_lock = threading.Lock()

    def deliver(comment):
        header = '[claude-review] comment {} {}'.format(comment['id'], location(comment))
        if comment['follow_up']:
            header += ' (follow-up)'
        text = comment['text'].rstrip('\n')
        try:
            # One write per block, so Monitor batches it into one notification.
            write_stdout('{}\n{}\n'.format(header, text), out_lock)
        except (IOError, OSError):
            return False
        return True

    done = threading.Event()

    def on_event(kind, detail=None):
        if kind == 'nvim_connected':
            write_stdout('[claude-review] neovim connected\n', out_lock)
        elif kind == 'nvim_disconnected':
            write_stdout('[claude-review] neovim disconnected\n', out_lock)
        elif kind == 'nvim_bye':
            write_stdout('[claude-review] stopped: neovim disconnected on purpose\n', out_lock)
            done.set()

    owner = Owner(owner_socket_path(args.socket), deliver, on_event)
    try:
        owner.bind()
    except BridgeError as err:
        write_stdout('[claude-review] error: {}\n'.format(err), out_lock)
        return 1
    install_signal_handlers(owner)
    try:
        while not done.wait(1.0):
            pass
    finally:
        owner.stop()
    return 0


# --------------------------------------------------------------------------
# mcp: channel mode

MCP_INSTRUCTIONS = """\
Review comments from the user's Neovim arrive as <channel source="nvim-bridge" \
comment_id=... path=... start_line=... end_line=...> messages. The body is the \
comment text; path is relative to the workspace root and the lines are 1-based. \
A message with follow_up="true" continues the thread of that comment_id.

For every comment: read the referenced lines, do what it asks (answer the \
question or make the change), then call `reply` with that comment_id. Set \
resolve=true when the comment is fully addressed. Never leave a comment \
without a reply.

When you change code or want the user to look at specific places, call \
`set_quickfix` with one item per location (path, lnum, text) so they open in \
Neovim's quickfix list. `list_comments` shows the open comments and \
`editor_state` shows the user's current file, cursor and last selection."""

MCP_TOOLS = [
    {
        'name': 'reply',
        'description': 'Reply to a Neovim review comment. The reply appears in the '
        "comment's thread in the editor. Set resolve=true when the comment is addressed.",
        'inputSchema': {
            'type': 'object',
            'properties': {
                'comment_id': {'type': 'string', 'description': 'The comment_id from the channel message.'},
                'text': {'type': 'string', 'description': 'Reply text (Markdown).'},
                'resolve': {'type': 'boolean', 'description': 'Mark the comment as resolved.'},
            },
            'required': ['comment_id', 'text'],
        },
    },
    {
        'name': 'set_quickfix',
        'description': "Load file locations into Neovim's quickfix list, e.g. the "
        'lines you changed or places worth reviewing.',
        'inputSchema': {
            'type': 'object',
            'properties': {
                'title': {'type': 'string', 'description': 'Quickfix list title.'},
                'items': {
                    'type': 'array',
                    'items': {
                        'type': 'object',
                        'properties': {
                            'path': {'type': 'string', 'description': 'File path, relative to the workspace root or absolute.'},
                            'lnum': {'type': 'integer', 'minimum': 1},
                            'end_lnum': {'type': 'integer', 'minimum': 1},
                            'col': {'type': 'integer', 'minimum': 1},
                            'text': {'type': 'string'},
                            'type': {'type': 'string', 'enum': ['E', 'W', 'I', 'N']},
                        },
                        'required': ['path', 'lnum', 'text'],
                    },
                },
                'mode': {'type': 'string', 'enum': ['replace', 'append'], 'default': 'replace'},
            },
            'required': ['title', 'items'],
        },
    },
    {
        'name': 'list_comments',
        'description': 'List review comments from Neovim, optionally filtered by state.',
        'inputSchema': {
            'type': 'object',
            'properties': {
                'state': {'type': 'string', 'enum': list(COMMENT_STATES)},
            },
        },
    },
    {
        'name': 'editor_state',
        'description': "The user's current Neovim file, cursor, last visual selection "
        'and open buffers.',
        'inputSchema': {'type': 'object', 'properties': {}},
    },
]

# Revisions answered with the legacy initialize handshake. Channel
# notifications need a legacy-era connection, so `server/discover` (the
# modern-era probe) gets method-not-found.
LEGACY_PROTOCOLS = ('2025-11-25', '2025-06-18', '2025-03-26', '2024-11-05')


class McpServer(object):
    def __init__(self, socket_path):
        self.out_lock = threading.Lock()
        self.owner = Owner(socket_path, self.deliver)
        self.initialized = threading.Event()

    def write(self, message):
        data = json.dumps(message, ensure_ascii=False) + '\n'
        with self.out_lock:
            sys.stdout.write(data)
            sys.stdout.flush()

    def deliver(self, comment):
        # Comments arriving before Claude finished the handshake would be lost.
        self.initialized.wait()
        meta = {
            'comment_id': comment['id'],
            'path': comment['path'],
            'start_line': str(comment['start_line']),
            'end_line': str(comment['end_line']),
        }
        if comment['follow_up']:
            meta['follow_up'] = 'true'
        try:
            self.write({
                'jsonrpc': '2.0',
                'method': 'notifications/claude/channel',
                'params': {'content': comment['text'], 'meta': meta},
            })
        except (IOError, OSError):
            return False
        return True

    def run(self):
        self.owner.bind()
        install_signal_handlers(self.owner)
        try:
            for line in sys.stdin:
                line = line.strip()
                if not line:
                    continue
                try:
                    message = json.loads(line)
                except ValueError:
                    self.write({
                        'jsonrpc': '2.0',
                        'id': None,
                        'error': {'code': -32700, 'message': 'parse error'},
                    })
                    continue
                if isinstance(message, dict):
                    self.dispatch(message)
        finally:
            self.owner.stop()

    def dispatch(self, message):
        method = message.get('method')
        if 'id' not in message:
            if method == 'notifications/initialized':
                self.initialized.set()
            return
        request_id = message['id']
        if method is None:
            return  # a response to a request we never send
        params = message.get('params') or {}
        if method == 'initialize':
            # Lenient towards clients that never send notifications/initialized.
            timer = threading.Timer(2.0, self.initialized.set)
            timer.daemon = True
            timer.start()
            requested = params.get('protocolVersion')
            version = requested if requested in LEGACY_PROTOCOLS else '2025-06-18'
            result = {
                'protocolVersion': version,
                'capabilities': {
                    'experimental': {'claude/channel': {}},
                    'tools': {},
                },
                'serverInfo': {'name': 'claude-review', 'version': MCP_SERVER_VERSION},
                'instructions': MCP_INSTRUCTIONS,
            }
        elif method == 'ping':
            result = {}
        elif method == 'tools/list':
            result = {'tools': MCP_TOOLS}
        elif method == 'tools/call':
            # Tool calls may wait on Neovim; keep reading stdin meanwhile.
            thread = threading.Thread(target=self.call_tool, args=(request_id, params))
            thread.daemon = True
            thread.start()
            return
        else:
            self.write({
                'jsonrpc': '2.0',
                'id': request_id,
                'error': {'code': -32601, 'message': 'method not found: {}'.format(method)},
            })
            return
        self.write({'jsonrpc': '2.0', 'id': request_id, 'result': result})

    def call_tool(self, request_id, params):
        name = params.get('name')
        arguments = params.get('arguments') or {}
        owner = self.owner
        try:
            if name == 'reply':
                status = owner.reply(
                    arguments.get('comment_id'), arguments.get('text'), arguments.get('resolve')
                )
                text = 'reply {}'.format(describe_status(status))
            elif name == 'set_quickfix':
                status = owner.quickfix(
                    arguments.get('title'), arguments.get('items'), arguments.get('mode') or 'replace'
                )
                text = 'quickfix list {}'.format(describe_status(status))
            elif name == 'list_comments':
                text = format_comments(owner.list_comments(arguments.get('state')))
            elif name == 'editor_state':
                text = json.dumps(owner.editor_state(), indent=2, ensure_ascii=False)
            else:
                raise BridgeError('unknown tool: {}'.format(name))
            result = {'content': [{'type': 'text', 'text': text}]}
        except BridgeError as err:
            result = {'content': [{'type': 'text', 'text': str(err)}], 'isError': True}
        self.write({'jsonrpc': '2.0', 'id': request_id, 'result': result})


def describe_status(status):
    if status == 'queued':
        return 'queued: Neovim is not connected; it is delivered when Neovim reconnects'
    return 'sent to Neovim'


def format_comments(listing):
    items = listing['items']
    if not items:
        return 'No comments.'
    lines = []
    for comment in items:
        lines.append('{} [{}] {}'.format(
            comment.get('id'), comment.get('state'), location(comment)
        ))
        for text_line in (comment.get('text') or '').splitlines():
            lines.append('    ' + text_line)
        for entry in comment.get('thread') or []:
            lines.append('  {}:'.format(entry.get('from')))
            for text_line in (entry.get('text') or '').splitlines():
                lines.append('    ' + text_line)
    if listing.get('source') == 'bridge':
        lines.append('(Neovim is not connected: only comments delivered in this session)')
    return '\n'.join(lines)


def cmd_mcp(args):
    server = McpServer(owner_socket_path(args.socket))
    try:
        server.run()
    except BridgeError as err:
        sys.stderr.write('claude-review: {}\n'.format(err))
        return 1
    return 0


# --------------------------------------------------------------------------
# CLI clients


def request(args, message):
    path = client_socket_path(args.socket)
    sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    sock.settimeout(REQUEST_TIMEOUT + 5)
    try:
        sock.connect(path)
    except (OSError, socket.error) as err:
        sock.close()
        raise BridgeError(
            'no claude-review owner at {} ({}). Start `claude-review --cli listen` '
            'or a `claude-review` session first.'.format(path, err.strerror or err)
        )
    try:
        sock.sendall(encode({'type': 'hello', 'role': 'cli', 'version': PROTOCOL_VERSION}))
        sock.sendall(encode(message))
        response = LineReader(sock).read()
    except socket.timeout:
        raise BridgeError('timed out waiting for the claude-review owner')
    finally:
        sock.close()
    if response is None:
        raise BridgeError('the claude-review owner closed the connection')
    if response.get('type') == 'error':
        raise BridgeError(response.get('message') or 'error')
    return response.get('result')


def read_text(value):
    if value == '-':
        return sys.stdin.read()
    return value


def cmd_reply(args):
    text = read_text(args.text)
    status = request(args, {
        'type': 'reply',
        'comment_id': args.comment_id,
        'text': text,
        'resolve': args.resolve,
    })
    print('reply {}: {}'.format(args.comment_id, status))
    return 0


def parse_qf_input(data):
    stripped = data.strip()
    if not stripped:
        raise BridgeError('no quickfix items on stdin')
    if stripped[0] in '[{':
        try:
            parsed = json.loads(stripped)
        except ValueError as err:
            raise BridgeError('invalid JSON on stdin: {}'.format(err))
        if isinstance(parsed, dict):
            parsed = parsed.get('items')
        return parsed
    items = []
    for number, line in enumerate(stripped.splitlines(), 1):
        if not line.strip():
            continue
        # path:lnum[:col]:text, the format of grep -n and most compilers.
        parts = line.split(':', 3)
        if len(parts) < 2 or not parts[1].strip().isdigit():
            raise BridgeError('line {}: expected path:lnum[:col]:text'.format(number))
        item = {'path': parts[0], 'lnum': int(parts[1])}
        rest = parts[2:]
        if len(rest) == 2 and rest[0].strip().isdigit():
            item['col'] = int(rest[0])
            item['text'] = rest[1].strip()
        else:
            item['text'] = ':'.join(rest).strip()
        items.append(item)
    return items


def cmd_qf(args):
    items = normalize_items(parse_qf_input(sys.stdin.read()))
    status = request(args, {
        'type': 'quickfix',
        'title': args.title,
        'mode': 'append' if args.append else 'replace',
        'items': items,
    })
    print('quickfix ({} items): {}'.format(len(items), status))
    return 0


def cmd_comments(args):
    listing = request(args, {'type': 'comments_req', 'state': args.state})
    if args.json:
        print(json.dumps(listing['items'], indent=2, ensure_ascii=False))
    else:
        print(format_comments(listing))
    return 0


def cmd_state(args):
    print(json.dumps(request(args, {'type': 'state_req'}), indent=2, ensure_ascii=False))
    return 0


def cmd_status(args):
    try:
        status = request(args, {'type': 'status'})
    except BridgeError as err:
        print('not running: {}'.format(err))
        return 1
    print(json.dumps(status, indent=2))
    return 0


def build_parser():
    parser = argparse.ArgumentParser(
        prog='claude-review --cli',
        description='Bridge between Neovim review comments and Claude Code.',
        epilog='The socket defaults to $' + SOCKET_ENV + ', then '
        '<workspace>/' + DEFAULT_RELATIVE + '. Client commands look for it in '
        'the current directory and its parents.',
    )
    parser.add_argument('--socket', metavar='PATH', help='Unix socket path')
    sub = parser.add_subparsers(dest='command', metavar='COMMAND')

    sub.add_parser(
        'listen',
        help='own the socket and print each comment to stdout (monitor mode)',
    ).set_defaults(func=cmd_listen)
    sub.add_parser(
        'mcp', help='own the socket and serve MCP on stdio (channel mode)'
    ).set_defaults(func=cmd_mcp)

    reply = sub.add_parser('reply', help='reply to a comment')
    reply.add_argument('comment_id')
    reply.add_argument('text', help='reply text, or - to read it from stdin')
    reply.add_argument('--resolve', action='store_true', help='mark the comment resolved')
    reply.set_defaults(func=cmd_reply)

    qf = sub.add_parser(
        'qf',
        help='send a quickfix list read from stdin: a JSON array of '
        '{path, lnum, text, end_lnum?, col?, type?}, or path:lnum[:col]:text lines',
    )
    qf.add_argument('--title', default='Claude', help='quickfix list title')
    qf.add_argument('--append', action='store_true', help='append to the current list')
    qf.set_defaults(func=cmd_qf)

    comments = sub.add_parser('comments', help='list comments')
    comments.add_argument('--state', choices=COMMENT_STATES)
    comments.add_argument('--json', action='store_true')
    comments.set_defaults(func=cmd_comments)

    sub.add_parser('state', help="print Neovim's current file, cursor and selection").set_defaults(
        func=cmd_state
    )
    sub.add_parser('status', help='show whether an owner and Neovim are connected').set_defaults(
        func=cmd_status
    )
    return parser


def main(argv=None):
    parser = build_parser()
    args = parser.parse_args(argv)
    if not getattr(args, 'func', None):
        parser.print_help()
        return 2
    try:
        return args.func(args)
    except BridgeError as err:
        sys.stderr.write('claude-review: {}\n'.format(err))
        return 1


if __name__ == '__main__':
    sys.exit(main())
