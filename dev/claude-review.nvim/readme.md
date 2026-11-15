# claude-review.nvim

Attach review comments to lines of any file in Neovim; Claude Code receives them
live, answers each one in the comment's thread and can send file:line lists that
Neovim loads into quickfix. Everything stays on the machine: a Unix socket at
`<workspace>/.cache/claude-review/bridge.sock`, newline-delimited JSON.

The repo is a Neovim plugin (`lua/`) and a Claude Code plugin
(`.claude-plugin/`, `.mcp.json`, `skills/`) at once. The bridge is
`bridge/bridge.py`: one file, Python 3.6+ stdlib only.

## Modes

| | Monitor mode | Channel mode |
|---|---|---|
| Start | Ask any `claude` session to "start the review monitor" | `claude-review` instead of `claude` |
| Socket owner | `claude-review --cli listen`, run by the `Monitor` tool | `bridge.py mcp`, the plugin's MCP server |
| Comments reach Claude as | Monitor notifications | `notifications/claude/channel` |
| Claude answers with | `claude-review --cli reply / qf` (Bash) | MCP tools `reply`, `set_quickfix`, `list_comments`, `editor_state` |
| Lifetime | 30 min per monitor; Claude re-arms it | The session |

One command serves both: `claude-review [ARGS...]` starts `claude` with this
plugin and its channel (ARGS pass through), and `claude-review --cli COMMAND`
is the bridge CLI. Monitor mode needs only that command on `PATH` and the
`claude-review` skill in `$CLAUDE_CONFIG_DIR/skills/` (both stowed by the
dotfiles). Channel mode needs the channels research preview (claude.ai login
or Console API key, not Bedrock/Vertex) and confirms the development channel
at startup.

## Neovim

```lua
require('claude-review').setup({
  socket = nil,         -- default: $CLAUDE_REVIEW_SOCK, then <cwd>/.cache/claude-review/bridge.sock
  auto_connect = true,  -- connect on startup and DirChanged, retrying with backoff
  send_on_add = false,  -- keep new comments as drafts until sent
  picker = 'quickfix',  -- or 'fzf' (fzf-lua) for :ClaudeReview list
})
```

States: `draft → sent → delivered → replied → resolved`. A comment stays `sent`
until the bridge acknowledges it, and is resent on every reconnect, so comments
written between monitor re-arms are not lost. Extmarks keep comments on their
lines while you edit; positions are written to `.cache/claude-review/comments.json`
on write and on exit.

`:ClaudeReview {subcommand}`:

| Subcommand | Keymap (dotfiles) | |
|---|---|---|
| `add` (accepts a range) | `;ca` (n, v) | New draft on the line or selection |
| `show` | `;cc` | Thread float: `r` follow-up, `R` resolve, `s` send, `e` edit, `q` close |
| `edit` | `;ce` | Edit a draft (shows the thread otherwise) |
| `reply` | `;cr` | Follow-up message on a sent comment |
| `delete` (accepts a range) | `;cd` (n, v) / `;cD` | Comment under the cursor, or every comment overlapping the range or selection (`;cD`: whole file). Asks before deleting more than one |
| `resolve` | `;cR` | Toggle resolved |
| `send` / `send_all` | `;cs` / `;cS` | Send the draft under the cursor / every draft |
| `list [quickfix\|fzf]` | `;cl` / `;cf` | Open comments in quickfix (`:ClaudeReview! list` includes resolved) |
| `connect [path]` / `disconnect` | | `disconnect` also stops a monitor-mode listener |
| `status` | | |

Text input floats submit with `:w` or `<C-s>` and discard with `q`. Replies show
as notifications and in the thread float; quickfix lists from Claude open with
quicker.nvim when present.

## CLI

```
claude-review --cli [--socket PATH] listen       # monitor-mode owner
claude-review --cli [--socket PATH] mcp          # channel-mode owner (stdio MCP)
claude-review --cli reply ID TEXT|- [--resolve]
claude-review --cli qf [--title T] [--append]    # stdin: JSON array or path:lnum[:col]:text lines
claude-review --cli comments [--state S] [--json]
claude-review --cli state                        # Neovim's file, cursor, last selection
claude-review --cli status
```

Client commands look for `.cache/claude-review/bridge.sock` in the current
directory and its parents. Replies and quickfix lists sent while Neovim is
away are queued by the owner and flushed when it reconnects. A second owner on
the same socket refuses to start (`bridge.sock.lock` holds an flock); a stale
socket file is replaced. With several Neovims on one socket the latest one
wins and the previous one stops reconnecting.

## Channel mode notes

- `--plugin-dir` plugins belong to the `inline` marketplace, so `claude-review`
  passes `--dangerously-load-development-channels plugin:claude-review@inline`.
- Channels are only delivered on legacy-era MCP connections. The server answers
  the `server/discover` probe with method-not-found, so Claude Code falls back to
  the `initialize` handshake (`protocolEra: legacy` in `--debug` logs) without
  `MCP_PROTOCOL_NEGOTIATION=legacy`.
- In channel sessions the skill is also loaded (as `claude-review:claude-review`);
  it tells Claude to use the MCP tools when they exist.

## Tests

```
python3 -m unittest discover -s tests              # bridge: listen, mcp, CLI
nvim --clean --headless -l tests/test_nvim.lua     # plugin against a fake owner
```
