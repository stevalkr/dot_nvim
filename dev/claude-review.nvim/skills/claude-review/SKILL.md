---
name: claude-review
description: Receive and answer review comments the user writes in Neovim (claude-review.nvim). Use when the user asks to start, restart or stop the review monitor, the Neovim review channel, or to watch for their Neovim comments; also when a `[claude-review]` monitor notification arrives or the monitor expires.
---

# Neovim review comments (monitor mode)

The user attaches comments to lines in Neovim. A listener owns the socket
`<workspace>/.cache/claude-review/bridge.sock` and prints each comment to
stdout; the `Monitor` tool turns those lines into notifications.

If MCP tools named `reply` and `set_quickfix` from the `nvim-bridge` server are
available, this session runs in channel mode: comments arrive as `<channel>`
messages and you answer with those tools. Do not start a monitor then.

## Start

From the workspace root (the directory Neovim was started in):

```
Monitor({
  command: "claude-review --cli listen",
  description: "claude-review comments (<workspace name>)",
  timeout_ms: 1800000
})
```

Add `--socket PATH` only if the user names a socket. If the first event is
`[claude-review] error: another claude-review owner already holds ...`, a
listener or channel session already serves this workspace: tell the user
instead of retrying.

## Events

```
[claude-review] comment c12 src/auth.rs:42-45
<comment text, possibly several lines>
```

- Paths are relative to the workspace root; lines are 1-based and inclusive.
- `(follow-up)` after the location means the user continued the thread of that
  comment. Run `claude-review --cli comments` to see the whole thread when you
  need the earlier context.
- `[claude-review] neovim connected` / `neovim disconnected` need no action.
  Comments written while you were away are delivered on reconnect.

## Answer every comment

1. Read the referenced lines (and enough context around them).
2. Do what the comment asks: answer the question, or make the change.
3. Reply, always, with the comment id from the event:

   ```
   claude-review --cli reply c12 "Short answer or summary of the change"
   claude-review --cli reply c12 --resolve - <<'EOF'
   Longer Markdown reply read from stdin.
   EOF
   ```

   Use `--resolve` when the comment is fully addressed.
4. When you changed code or want the user to look at specific places, send a
   quickfix list (one location per line, `path:lnum[:col]:text`, or a JSON array
   of `{path, lnum, text, end_lnum?, col?, type?}`):

   ```
   claude-review --cli qf --title "c12: token refresh" <<'EOF'
   src/auth.rs:42:refresh now retries once
   src/auth.rs:88:new helper
   EOF
   ```

   `--append` adds to the user's current list instead of replacing it.

Other commands: `claude-review --cli comments [--state sent]` lists comments,
`claude-review --cli state` shows the user's current file, cursor and last
selection, `claude-review --cli status` shows whether Neovim is connected.

A reply or quickfix list sent while Neovim is disconnected is queued and
delivered when it reconnects; the command then prints `queued`.

## Expiry and stopping

- A monitor runs at most 30 minutes. On the expiry notice, start it again with
  the same command, without asking, unless the user asked you to stop.
- `[claude-review] stopped: neovim disconnected on purpose` means the user ran
  `:ClaudeReview disconnect`: do not restart.
- To stop on request, stop the monitor task (TaskStop).
- If the monitor exits with an error, report the error line to the user.
