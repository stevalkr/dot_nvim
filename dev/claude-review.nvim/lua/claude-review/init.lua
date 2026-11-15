-- Review comments from Neovim to Claude Code over the claude-review bridge.
local client = require('claude-review.client')
local store = require('claude-review.store')
local ui = require('claude-review.ui')

local M = {}

local config = {
  ---@type string? Socket path; defaults to $CLAUDE_REVIEW_SOCK, then
  --- <cwd>/.cache/claude-review/bridge.sock.
  socket = nil,
  --- Connect on startup and on DirChanged.
  auto_connect = true,
  --- Send a new comment immediately instead of keeping it as a draft.
  send_on_add = false,
  ---@type 'quickfix'|'fzf'
  picker = 'quickfix',
}

-- `:ClaudeReview connect {path}` overrides the configured socket.
local socket_override = nil
-- The last window showing a file, for `state_req` while a terminal has focus.
local last_file_win = nil

local function notify(message, level)
  vim.notify('claude-review: ' .. message, level or vim.log.levels.INFO)
end

local function socket_path()
  return socket_override
    or config.socket
    or (vim.env.CLAUDE_REVIEW_SOCK ~= '' and vim.env.CLAUDE_REVIEW_SOCK)
    or vim.fs.joinpath(store.root, '.cache', 'claude-review', 'bridge.sock')
end

local function persist(path)
  ui.sync()
  store.save()
  ui.refresh(path)
end

local function location(comment)
  if comment.end_line > comment.start_line then
    return string.format(
      '%s:%d-%d',
      comment.path,
      comment.start_line,
      comment.end_line
    )
  end
  return string.format('%s:%d', comment.path, comment.start_line)
end

---------------------------------------------------------------------------
-- Incoming messages

local handlers = {}

function handlers.ack(message)
  local comment = store.ack(message.id)
  if comment then
    persist(comment.path)
  end
end

function handlers.reply(message)
  local comment = store.reply(message.comment_id, message.text, message.resolve)
  if not comment then
    notify(
      string.format(
        'reply for unknown comment %s:\n%s',
        message.comment_id,
        message.text
      ),
      vim.log.levels.WARN
    )
    return
  end
  persist(comment.path)
  notify(
    string.format(
      'Claude %s %s (%s):\n%s',
      message.resolve and 'resolved' or 'replied to',
      comment.id,
      location(comment),
      message.text
    )
  )
end

function handlers.quickfix(message)
  local items = {}
  for _, item in ipairs(message.items or {}) do
    table.insert(items, {
      filename = store.absolute(item.path),
      lnum = item.lnum,
      end_lnum = item.end_lnum,
      col = item.col,
      text = item.text,
      type = item.type,
    })
  end
  local action = message.mode == 'append' and 'a' or ' '
  vim.fn.setqflist(
    {},
    action,
    { title = message.title or 'Claude', items = items }
  )
  local ok, quicker = pcall(require, 'quicker')
  if ok then
    quicker.open({ focus = false })
  else
    vim.cmd('botright copen')
    vim.cmd.wincmd('p')
  end
  notify(
    string.format(
      '%d quickfix items from Claude: %s',
      #items,
      message.title or ''
    )
  )
end

local function serializable_comments(state)
  ui.sync()
  local items = {}
  for _, comment in ipairs(store.list()) do
    if state == nil or comment.state == state then
      local copy = {}
      for key, value in pairs(comment) do
        if key:sub(1, 1) ~= '_' then
          copy[key] = value
        end
      end
      table.insert(items, copy)
    end
  end
  return items
end

function handlers.comments_req(message)
  client.send({
    type = 'comments',
    req_id = message.req_id,
    items = serializable_comments(message.state),
  })
end

function handlers.state_req(message)
  local win = vim.api.nvim_get_current_win()
  if vim.bo[vim.api.nvim_win_get_buf(win)].buftype ~= '' then
    win = (last_file_win and vim.api.nvim_win_is_valid(last_file_win))
        and last_file_win
      or win
  end
  local buf = vim.api.nvim_win_get_buf(win)
  local cursor = vim.api.nvim_win_get_cursor(win)
  local response = {
    type = 'state',
    req_id = message.req_id,
    root = store.root,
    path = store.buf_path(buf),
    filetype = vim.bo[buf].filetype,
    modified = vim.bo[buf].modified,
    cursor = { line = cursor[1], col = cursor[2] + 1 },
    buffers = {},
  }
  local start_mark = vim.api.nvim_buf_get_mark(buf, '<')
  local end_mark = vim.api.nvim_buf_get_mark(buf, '>')
  if start_mark[1] > 0 and end_mark[1] > 0 then
    response.last_selection =
      { start_line = start_mark[1], end_line = end_mark[1] }
  end
  for _, other in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[other].buflisted then
      local path = store.buf_path(other)
      if path then
        table.insert(response.buffers, path)
      end
    end
  end
  client.send(response)
end

function handlers.error(message)
  if message.code == 'replaced' then
    -- Do not fight the other Neovim for the socket.
    client.disconnect(false)
    notify(
      'disconnected: ' .. (message.message or 'replaced'),
      vim.log.levels.WARN
    )
    return
  end
  notify(message.message or 'bridge error', vim.log.levels.ERROR)
end

client.on_message = function(message)
  local handler = handlers[message.type]
  if handler then
    handler(message)
  end
end

client.on_connect = function()
  for _, payload in ipairs(store.unacked()) do
    client.send(payload)
  end
end

---------------------------------------------------------------------------
-- Comments under the cursor

local function cursor_comments()
  local buf = vim.api.nvim_get_current_buf()
  local path = store.buf_path(buf)
  if not path then
    return {}
  end
  ui.sync(buf)
  local line = vim.api.nvim_win_get_cursor(0)[1]
  local result = vim.tbl_filter(function(comment)
    return comment.start_line <= line and line <= comment.end_line
  end, store.for_path(path))
  -- Innermost (shortest) range first.
  table.sort(result, function(a, b)
    return (a.end_line - a.start_line) < (b.end_line - b.start_line)
  end)
  return result
end

---@param callback fun(comment: table)
---@param filter? fun(comment: table): boolean
local function with_cursor_comment(callback, filter)
  local comments = cursor_comments()
  if filter then
    comments = vim.tbl_filter(filter, comments)
  end
  if #comments == 0 then
    notify('no comment under the cursor', vim.log.levels.WARN)
  elseif #comments == 1 then
    callback(comments[1])
  else
    vim.ui.select(comments, {
      prompt = 'Comment',
      format_item = function(comment)
        return string.format(
          '%s [%s] %s',
          comment.id,
          comment.state,
          comment.text
        )
      end,
    }, function(choice)
      if choice then
        callback(choice)
      end
    end)
  end
end

---------------------------------------------------------------------------
-- Actions

local function ensure_connected()
  if not client.connected() then
    client.connect(socket_path())
  end
end

local function send_comment(comment)
  ui.sync()
  comment.state = 'sent'
  comment.acked = false
  persist(comment.path)
  ensure_connected()
  if not client.send(store.payload(comment)) then
    notify(
      comment.id
        .. ' is waiting for the bridge (start the Claude review monitor)'
    )
  end
end

local function send_follow_up(comment, text)
  local entry = store.follow_up(comment, text)
  persist(comment.path)
  ensure_connected()
  if not client.send(store.payload(comment, entry)) then
    notify(comment.id .. ' follow-up is waiting for the bridge')
  end
end

--- Add a comment on lines `line1`..`line2` of the current buffer (default:
--- the cursor line, or the visual selection in visual mode).
---@param opts? { line1?: integer, line2?: integer }
--- Lines of the visual selection (leaving visual mode), or the cursor line.
---@return integer, integer
local function selection_range()
  local line1, line2
  local mode = vim.fn.mode()
  if mode == 'v' or mode == 'V' or mode == '\22' then
    line1, line2 = vim.fn.line('v'), vim.fn.line('.')
    vim.api.nvim_feedkeys(vim.keycode('<Esc>'), 'nx', false)
  else
    line1 = vim.api.nvim_win_get_cursor(0)[1]
    line2 = line1
  end
  if line1 > line2 then
    line1, line2 = line2, line1
  end
  return line1, line2
end

function M.add(opts)
  opts = opts or {}
  local buf = vim.api.nvim_get_current_buf()
  local path = store.buf_path(buf)
  if not path then
    notify('the current buffer is not a file', vim.log.levels.WARN)
    return
  end
  local line1, line2 = opts.line1, opts.line2
  if not line1 then
    line1, line2 = selection_range()
  end
  local title = line1 == line2 and string.format('%s:%d', path, line1)
    or string.format('%s:%d-%d', path, line1, line2)
  ui.input({
    title = 'Comment on ' .. title,
    on_submit = function(text)
      local comment = store.add(path, line1, line2, text)
      persist(path)
      if config.send_on_add then
        send_comment(comment)
      end
    end,
  })
end

local thread_actions

local function edit_comment(comment)
  if comment.state ~= 'draft' then
    M.show(comment)
    return
  end
  ui.input({
    title = 'Edit ' .. comment.id,
    text = comment.text,
    on_submit = function(text)
      comment.text = text
      persist(comment.path)
    end,
  })
end

local function follow_up(comment)
  if comment.state == 'draft' then
    edit_comment(comment)
    return
  end
  ui.input({
    title = 'Follow-up on ' .. comment.id,
    on_submit = function(text)
      send_follow_up(comment, text)
    end,
  })
end

local function delete_comment(comment)
  ui.close_thread()
  store.remove(comment.id)
  persist(comment.path)
  notify('deleted ' .. comment.id)
end

local function resolve_comment(comment)
  if comment.state ~= 'resolved' then
    comment.state = 'resolved'
  elseif
    vim.iter(comment.thread):any(function(entry)
      return entry.from == 'claude'
    end)
  then
    comment.state = 'replied'
  else
    comment.state = comment.acked and 'delivered' or 'sent'
  end
  persist(comment.path)
end

thread_actions = {
  r = { desc = 'follow-up', fn = follow_up },
  R = { desc = 'resolve', fn = resolve_comment },
  s = {
    desc = 'send',
    fn = function(comment)
      if comment.state == 'draft' then
        send_comment(comment)
      end
    end,
  },
  e = { desc = 'edit', fn = edit_comment },
}

--- Show a comment's thread in a float.
function M.show(comment)
  if comment then
    ui.show_thread(comment, thread_actions)
  else
    with_cursor_comment(M.show)
  end
end

function M.edit()
  with_cursor_comment(edit_comment)
end

function M.follow_up()
  with_cursor_comment(follow_up)
end

--- Delete the comment under the cursor or, given a range or a visual
--- selection, every comment overlapping those lines.
---@param opts? { line1: integer, line2: integer }
function M.delete(opts)
  opts = opts or {}
  local line1, line2 = opts.line1, opts.line2
  if not line1 then
    local mode = vim.fn.mode()
    if mode ~= 'v' and mode ~= 'V' and mode ~= '\22' then
      with_cursor_comment(delete_comment)
      return
    end
    line1, line2 = selection_range()
  end
  local buf = vim.api.nvim_get_current_buf()
  local path = store.buf_path(buf)
  if not path then
    notify('the current buffer is not a file', vim.log.levels.WARN)
    return
  end
  ui.sync(buf)
  local comments = vim.tbl_filter(function(comment)
    return comment.start_line <= line2 and line1 <= comment.end_line
  end, store.for_path(path))
  if #comments == 0 then
    notify('no comments in range', vim.log.levels.WARN)
    return
  end
  if
    #comments > 1
    and vim.fn.confirm(
        string.format('Delete %d comments?', #comments),
        '&Yes\n&No',
        2
      )
      ~= 1
  then
    return
  end
  ui.close_thread()
  for _, comment in ipairs(comments) do
    store.remove(comment.id)
  end
  persist(path)
  notify(string.format('deleted %d comment(s)', #comments))
end

function M.resolve()
  with_cursor_comment(resolve_comment)
end

--- Send the draft under the cursor.
function M.send()
  with_cursor_comment(send_comment, function(comment)
    return comment.state == 'draft'
  end)
end

function M.send_all()
  local drafts = store.list(function(comment)
    return comment.state == 'draft'
  end)
  if #drafts == 0 then
    notify('no drafts to send')
    return
  end
  for _, comment in ipairs(drafts) do
    send_comment(comment)
  end
  notify(string.format('sent %d draft(s)', #drafts))
end

---@param opts? { picker?: 'quickfix'|'fzf', all?: boolean }
function M.list(opts)
  opts = opts or {}
  ui.sync()
  local items = {}
  for _, comment in ipairs(store.list()) do
    if opts.all or comment.state ~= 'resolved' then
      table.insert(items, {
        filename = store.absolute(comment.path),
        lnum = comment.start_line,
        end_lnum = comment.end_line,
        text = string.format(
          '[%s %s] %s',
          comment.id,
          comment.state,
          (comment.text:gsub('\n', ' '))
        ),
        type = comment.state == 'replied' and 'W' or 'I',
      })
    end
  end
  vim.fn.setqflist({}, ' ', { title = 'Claude review comments', items = items })
  if #items == 0 then
    notify('no open comments')
    return
  end
  local picker = opts.picker or config.picker
  if picker == 'fzf' and pcall(require, 'fzf-lua') then
    require('fzf-lua').quickfix()
    return
  end
  local ok, quicker = pcall(require, 'quicker')
  if ok then
    quicker.open()
  else
    vim.cmd('botright copen')
  end
end

---@param path? string
function M.connect(path)
  if path and path ~= '' then
    socket_override = vim.fs.normalize(vim.fs.abspath(path))
  end
  client.connect(socket_path())
end

function M.disconnect()
  client.disconnect(true)
  notify('disconnected')
end

function M.status()
  local counts = {}
  for _, comment in ipairs(store.list()) do
    counts[comment.state] = (counts[comment.state] or 0) + 1
  end
  local parts = {}
  for _, state in ipairs(store.states) do
    if counts[state] then
      table.insert(parts, string.format('%d %s', counts[state], state))
    end
  end
  notify(
    string.format(
      '%s %s\ncomments: %s',
      client.connected() and 'connected to' or 'not connected to',
      client.path() or socket_path(),
      #parts > 0 and table.concat(parts, ', ') or 'none'
    )
  )
end

---------------------------------------------------------------------------
-- Setup

local subcommands = {
  add = function(opts)
    M.add(opts.range > 0 and { line1 = opts.line1, line2 = opts.line2 } or nil)
  end,
  show = function()
    M.show()
  end,
  edit = M.edit,
  reply = M.follow_up,
  delete = function(opts)
    M.delete(
      opts.range > 0 and { line1 = opts.line1, line2 = opts.line2 } or nil
    )
  end,
  resolve = M.resolve,
  send = M.send,
  send_all = M.send_all,
  list = function(opts)
    M.list({ picker = opts.fargs[2], all = opts.bang })
  end,
  connect = function(opts)
    M.connect(opts.fargs[2])
  end,
  disconnect = M.disconnect,
  status = M.status,
}

local function change_root(root)
  ui.sync()
  store.save()
  store.load(root)
  ui.refresh()
  if not socket_override and not config.socket and config.auto_connect then
    client.close()
    client.connect(socket_path())
  end
end

---@param opts? table
function M.setup(opts)
  config = vim.tbl_deep_extend('force', config, opts or {})
  ui.define_highlights()
  store.load(vim.fn.getcwd())

  vim.api.nvim_create_user_command('ClaudeReview', function(cmd)
    local name = cmd.fargs[1] or 'status'
    local fn = subcommands[name]
    if not fn then
      notify('unknown subcommand: ' .. name, vim.log.levels.ERROR)
      return
    end
    fn(cmd)
  end, {
    nargs = '*',
    range = true,
    bang = true,
    desc = 'Claude review comments',
    complete = function(_, line)
      local words = vim.split(line, '%s+', { trimempty = true })
      if #words <= 1 or (#words == 2 and not line:match('%s$')) then
        return vim.tbl_keys(subcommands)
      end
      if words[2] == 'list' then
        return { 'quickfix', 'fzf' }
      end
      if words[2] == 'connect' then
        return vim.fn.getcompletion(words[3] or '', 'file')
      end
      return {}
    end,
  })

  local group = vim.api.nvim_create_augroup('ClaudeReview', { clear = true })
  vim.api.nvim_create_autocmd('ColorScheme', {
    group = group,
    callback = ui.define_highlights,
  })
  vim.api.nvim_create_autocmd({ 'BufReadPost', 'BufNewFile' }, {
    group = group,
    callback = function(ev)
      ui.render(ev.buf)
    end,
  })
  vim.api.nvim_create_autocmd('BufWritePost', {
    group = group,
    callback = function(ev)
      local path = store.buf_path(ev.buf)
      if path and #store.for_path(path) > 0 then
        ui.sync(ev.buf)
        store.save()
      end
    end,
  })
  vim.api.nvim_create_autocmd('BufUnload', {
    group = group,
    callback = function(ev)
      ui.detach(ev.buf)
    end,
  })
  vim.api.nvim_create_autocmd('BufEnter', {
    group = group,
    callback = function(ev)
      if vim.bo[ev.buf].buftype == '' then
        last_file_win = vim.api.nvim_get_current_win()
      end
    end,
  })
  vim.api.nvim_create_autocmd('DirChanged', {
    group = group,
    callback = function()
      if vim.v.event.scope == 'global' and vim.v.event.cwd ~= store.root then
        change_root(vim.v.event.cwd)
      end
    end,
  })
  vim.api.nvim_create_autocmd('VimLeavePre', {
    group = group,
    callback = function()
      ui.sync()
      store.save()
      client.close()
    end,
  })

  ui.refresh()
  if config.auto_connect then
    client.connect(socket_path())
  end
end

return M
