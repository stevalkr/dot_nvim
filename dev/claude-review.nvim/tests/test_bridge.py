"""Bridge tests: drive `listen` and `mcp` as subprocesses with a fake Neovim.

Run with: python3 -m unittest discover -s tests
"""

import json
import os
import select
import shutil
import socket
import subprocess
import sys
import tempfile
import time
import unittest

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BRIDGE = os.path.join(ROOT, 'bridge', 'bridge.py')
TIMEOUT = 5.0


def wait_for(predicate, timeout=TIMEOUT):
    deadline = time.time() + timeout
    while time.time() < deadline:
        result = predicate()
        if result:
            return result
        time.sleep(0.02)
    raise AssertionError('timed out')


class FakeNvim(object):
    def __init__(self, path):
        self.sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        wait_for(lambda: self.try_connect(path))
        self.buffer = b''
        self.send({'type': 'hello', 'role': 'nvim', 'version': 1})

    def try_connect(self, path):
        try:
            self.sock.connect(path)
            return True
        except OSError:
            return False

    def send(self, message):
        self.sock.sendall((json.dumps(message) + '\n').encode('utf-8'))

    def recv(self, timeout=TIMEOUT):
        deadline = time.time() + timeout
        while b'\n' not in self.buffer:
            remaining = deadline - time.time()
            if remaining <= 0:
                raise AssertionError('no message from the owner')
            ready, _, _ = select.select([self.sock], [], [], remaining)
            if ready:
                chunk = self.sock.recv(65536)
                if not chunk:
                    raise AssertionError('owner closed the connection')
                self.buffer += chunk
        line, self.buffer = self.buffer.split(b'\n', 1)
        return json.loads(line.decode('utf-8'))

    def close(self):
        self.sock.close()


class StdoutReader(object):
    def __init__(self, proc):
        self.proc = proc
        self.buffer = b''

    def line(self, timeout=TIMEOUT):
        fd = self.proc.stdout.fileno()
        deadline = time.time() + timeout
        while b'\n' not in self.buffer:
            remaining = deadline - time.time()
            if remaining <= 0:
                raise AssertionError('no output; buffered: %r' % self.buffer)
            ready, _, _ = select.select([fd], [], [], remaining)
            if ready:
                chunk = os.read(fd, 65536)
                if not chunk:
                    raise AssertionError('process exited; buffered: %r' % self.buffer)
                self.buffer += chunk
        line, self.buffer = self.buffer.split(b'\n', 1)
        return line.decode('utf-8')


class BridgeTestCase(unittest.TestCase):
    def setUp(self):
        # Short path: Unix socket paths are limited to ~104 bytes on macOS.
        self.tmp = tempfile.mkdtemp(prefix='cr', dir='/tmp')
        self.sock = os.path.join(self.tmp, 'bridge.sock')
        self.procs = []
        self.clients = []

    def tearDown(self):
        for client in self.clients:
            client.close()
        for proc in self.procs:
            if proc.poll() is None:
                proc.terminate()
                proc.wait(TIMEOUT)
            for stream in (proc.stdin, proc.stdout, proc.stderr):
                if stream:
                    stream.close()
        shutil.rmtree(self.tmp, ignore_errors=True)

    def spawn(self, *args, **kwargs):
        proc = subprocess.Popen(
            [sys.executable, BRIDGE, '--socket', self.sock] + list(args),
            stdin=kwargs.get('stdin', subprocess.DEVNULL),
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            cwd=self.tmp,
        )
        self.procs.append(proc)
        return proc

    def cli(self, *args, **kwargs):
        return subprocess.run(
            [sys.executable, BRIDGE, '--socket', self.sock] + list(args),
            input=kwargs.get('input', '').encode('utf-8'),
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            timeout=TIMEOUT * 2,
            cwd=kwargs.get('cwd', self.tmp),
        )

    def nvim(self):
        client = FakeNvim(self.sock)
        self.clients.append(client)
        return client

    def comment(self, **extra):
        message = {
            'type': 'comment',
            'id': 'c1',
            'path': 'src/a.py',
            'start_line': 3,
            'end_line': 5,
            'text': 'Why?\nSecond line',
        }
        message.update(extra)
        return message


class ListenTest(BridgeTestCase):
    def start(self):
        proc = self.spawn('listen')
        out = StdoutReader(proc)
        wait_for(lambda: os.path.exists(self.sock))
        return proc, out

    def test_comment_block_and_ack(self):
        proc, out = self.start()
        nvim = self.nvim()
        self.assertEqual(out.line(), '[claude-review] neovim connected')
        nvim.send(self.comment())
        self.assertEqual(out.line(), '[claude-review] comment c1 src/a.py:3-5')
        self.assertEqual(out.line(), 'Why?')
        self.assertEqual(out.line(), 'Second line')
        self.assertEqual(nvim.recv(), {'type': 'ack', 'id': 'c1'})

        # A resend after a lost ack is acknowledged without printing again.
        nvim.send(self.comment())
        self.assertEqual(nvim.recv(), {'type': 'ack', 'id': 'c1'})

        nvim.send(self.comment(id='c1.2', thread_id='c1', text='More', start_line=4, end_line=4))
        self.assertEqual(out.line(), '[claude-review] comment c1 src/a.py:4 (follow-up)')
        self.assertEqual(out.line(), 'More')
        self.assertEqual(nvim.recv(), {'type': 'ack', 'id': 'c1.2'})

    def test_reply_quickfix_and_queue(self):
        proc, out = self.start()
        nvim = self.nvim()
        out.line()
        nvim.send(self.comment())
        nvim.recv()

        result = self.cli('reply', 'c1', 'Because.', '--resolve')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn(b'sent', result.stdout)
        self.assertEqual(
            nvim.recv(),
            {'type': 'reply', 'comment_id': 'c1', 'text': 'Because.', 'resolve': True},
        )

        # A reply addressed to a follow-up message goes to its root comment.
        nvim.send(self.comment(id='c1.2', thread_id='c1', text='More'))
        nvim.recv()
        self.cli('reply', 'c1.2', '-', input='multi\nline\n')
        self.assertEqual(nvim.recv()['comment_id'], 'c1')

        result = self.cli(
            'qf', '--title', 'Changes', input='src/a.py:10:fixed here\nsrc/b.py:2:5:col: x\n'
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        message = nvim.recv()
        self.assertEqual(message['title'], 'Changes')
        self.assertEqual(message['mode'], 'replace')
        self.assertEqual(
            message['items'],
            [
                {'path': 'src/a.py', 'lnum': 10, 'text': 'fixed here'},
                {'path': 'src/b.py', 'lnum': 2, 'col': 5, 'text': 'col: x'},
            ],
        )

        result = self.cli('qf', '--append', input=json.dumps([{'path': 'c.py', 'lnum': 1, 'text': 't'}]))
        self.assertEqual(nvim.recv()['mode'], 'append')

        nvim.close()
        self.clients.remove(nvim)
        wait_for(lambda: out.line() == '[claude-review] neovim disconnected')
        result = self.cli('reply', 'c1', 'later')
        self.assertIn(b'queued', result.stdout)
        nvim = self.nvim()
        self.assertEqual(nvim.recv()['text'], 'later')

    def test_comments_and_state_requests(self):
        proc, out = self.start()
        nvim = self.nvim()
        out.line()

        result = self.cli('state')
        self.assertNotEqual(result.returncode, 0)  # the fake ignores state_req
        self.assertEqual(nvim.recv()['type'], 'state_req')

        def answer(kind, payload):
            request = nvim.recv()
            self.assertEqual(request['type'], kind)
            payload['req_id'] = request['req_id']
            nvim.send(payload)

        proc_cli = subprocess.Popen(
            [sys.executable, BRIDGE, '--socket', self.sock, 'comments', '--json'],
            stdout=subprocess.PIPE,
        )
        answer('comments_req', {'type': 'comments', 'items': [{'id': 'c9', 'state': 'draft'}]})
        stdout, _ = proc_cli.communicate(timeout=TIMEOUT)
        self.assertEqual(json.loads(stdout.decode('utf-8')), [{'id': 'c9', 'state': 'draft'}])

    def test_client_finds_socket_in_parent(self):
        os.makedirs(os.path.join(self.tmp, '.cache', 'claude-review'))
        os.makedirs(os.path.join(self.tmp, 'sub', 'dir'))
        proc = subprocess.Popen(
            [sys.executable, BRIDGE, 'listen'],
            stdout=subprocess.PIPE,
            cwd=self.tmp,
        )
        self.procs.append(proc)
        wait_for(lambda: os.path.exists(os.path.join(self.tmp, '.cache', 'claude-review', 'bridge.sock')))
        result = subprocess.run(
            [sys.executable, BRIDGE, 'status'],
            stdout=subprocess.PIPE,
            cwd=os.path.join(self.tmp, 'sub', 'dir'),
            timeout=TIMEOUT,
        )
        self.assertEqual(result.returncode, 0)
        self.assertFalse(json.loads(result.stdout.decode('utf-8'))['nvim_connected'])

    def test_second_owner_refused_and_stale_socket(self):
        proc, out = self.start()
        second = self.spawn('listen')
        self.assertEqual(second.wait(TIMEOUT), 1)
        self.assertIn(b'another claude-review owner', second.stdout.read())

        proc.terminate()
        proc.wait(TIMEOUT)
        # Leave a stale socket file behind, as after a crash.
        stale = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        stale.bind(self.sock)
        stale.close()
        third, out = self.start()
        self.nvim()
        self.assertEqual(out.line(), '[claude-review] neovim connected')

    def test_bye_stops_listener(self):
        proc, out = self.start()
        nvim = self.nvim()
        out.line()
        nvim.send({'type': 'bye'})
        self.assertIn('stopped', out.line())
        self.assertEqual(proc.wait(TIMEOUT), 0)
        self.assertFalse(os.path.exists(self.sock))

    def test_no_owner(self):
        result = self.cli('reply', 'c1', 'x')
        self.assertEqual(result.returncode, 1)
        self.assertIn(b'no claude-review owner', result.stderr)


class McpTest(BridgeTestCase):
    def start(self):
        proc = self.spawn('mcp', stdin=subprocess.PIPE)
        self.out = StdoutReader(proc)
        self.proc = proc
        self.next_id = 0
        return proc

    def rpc(self, method, params=None):
        self.next_id += 1
        self.write({'jsonrpc': '2.0', 'id': self.next_id, 'method': method, 'params': params or {}})
        while True:
            message = json.loads(self.out.line())
            if message.get('id') == self.next_id:
                return message

    def write(self, message):
        self.proc.stdin.write((json.dumps(message) + '\n').encode('utf-8'))
        self.proc.stdin.flush()

    def handshake(self):
        discover = self.rpc('server/discover')
        self.assertEqual(discover['error']['code'], -32601)
        init = self.rpc('initialize', {'protocolVersion': '2025-11-25', 'capabilities': {}})
        self.write({'jsonrpc': '2.0', 'method': 'notifications/initialized'})
        return init['result']

    def test_handshake_and_tools(self):
        self.start()
        result = self.handshake()
        self.assertEqual(result['protocolVersion'], '2025-11-25')
        self.assertIn('claude/channel', result['capabilities']['experimental'])
        self.assertIn('reply', result['instructions'])
        tools = self.rpc('tools/list')['result']['tools']
        self.assertEqual(
            sorted(tool['name'] for tool in tools),
            ['editor_state', 'list_comments', 'reply', 'set_quickfix'],
        )
        init = self.rpc('initialize', {'protocolVersion': '2099-01-01'})
        self.assertEqual(init['result']['protocolVersion'], '2025-06-18')

    def test_channel_notification_and_reply(self):
        self.start()
        self.handshake()
        nvim = self.nvim()
        nvim.send(self.comment())
        notification = json.loads(self.out.line())
        self.assertEqual(notification['method'], 'notifications/claude/channel')
        self.assertEqual(notification['params']['content'], 'Why?\nSecond line')
        self.assertEqual(
            notification['params']['meta'],
            {'comment_id': 'c1', 'path': 'src/a.py', 'start_line': '3', 'end_line': '5'},
        )
        self.assertEqual(nvim.recv(), {'type': 'ack', 'id': 'c1'})

        response = self.rpc('tools/call', {
            'name': 'reply',
            'arguments': {'comment_id': 'c1', 'text': 'Done', 'resolve': True},
        })
        self.assertNotIn('isError', response['result'])
        self.assertEqual(nvim.recv()['text'], 'Done')

        response = self.rpc('tools/call', {
            'name': 'set_quickfix',
            'arguments': {'title': 'T', 'items': [{'path': 'a', 'lnum': 0, 'text': 'x'}]},
        })
        self.assertTrue(response['result']['isError'])

        # Neovim does not answer comments_req: the bridge falls back to its own record.
        response = self.rpc('tools/call', {'name': 'list_comments', 'arguments': {}})
        text = response['result']['content'][0]['text']
        self.assertIn('c1 [resolved] src/a.py:3-5', text)
        self.assertIn('Done', text)
        nvim.recv()  # the unanswered comments_req

    def test_owner_stops_with_stdin(self):
        proc = self.start()
        self.handshake()
        wait_for(lambda: os.path.exists(self.sock))
        proc.stdin.close()
        self.assertEqual(proc.wait(TIMEOUT), 0)
        self.assertFalse(os.path.exists(self.sock))


if __name__ == '__main__':
    unittest.main()
