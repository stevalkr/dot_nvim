-- Signs, virtual text and floats. Extmarks anchor comments while their buffer
-- is loaded; `sync` writes the anchored lines back into the store.
local store = require('claude-review.store')

local M = {}

M.ns = vim.api.nvim_create_namespace('claude-review')

local signs = {
  draft = '◌',
  sent = '◔',
  delivered = '◑',
  replied = '●',
  resolved = '✓',
}

local highlights = {
  draft = 'ClaudeReviewDraft',
  sent = 'ClaudeReviewSent',
  delivered = 'ClaudeReviewDelivered',
  replied = 'ClaudeReviewReplied',
  resolved = 'ClaudeReviewResolved',
}

function M.define_highlights()
  local links = {
    ClaudeReviewDraft = 'DiagnosticHint',
    ClaudeReviewSent = 'DiagnosticInfo',
    ClaudeReviewDelivered = 'DiagnosticInfo',
    ClaudeReviewReplied = 'DiagnosticWarn',
    ClaudeReviewResolved = 'Comment',
  }
  for group, link in pairs(links) do
    vim.api.nvim_set_hl(0, group, { link = link, default = true })
  end
end

local function first_line(text)
  local line = vim.split(text or '', '\n', { plain = true })[1] or ''
  if vim.fn.strchars(line) > 60 then
    line = vim.fn.strcharpart(line, 0, 59) .. '…'
  end
  return line
end

--- Copy extmark positions of `buf` (or every buffer) back into the store.
---@param buf? integer
function M.sync(buf)
  for _, comment in ipairs(store.data.comments) do
    if
      comment._buf
      and (buf == nil or comment._buf == buf)
      and vim.api.nvim_buf_is_valid(comment._buf)
    then
      local mark = vim.api.nvim_buf_get_extmark_by_id(
        comment._buf,
        M.ns,
        comment._mark,
        { details = true }
      )
      if mark[1] and not mark[3].invalid then
        comment.start_line = mark[1] + 1
        comment.end_line =
          math.max(comment.start_line, (mark[3].end_row or mark[1]) + 1)
      end
    end
  end
end

--- Forget the extmarks of an unloaded buffer, keeping their last position.
function M.detach(buf)
  M.sync(buf)
  for _, comment in ipairs(store.data.comments) do
    if comment._buf == buf then
      comment._buf, comment._mark = nil, nil
    end
  end
end

---@param buf integer
function M.render(buf)
  if not vim.api.nvim_buf_is_loaded(buf) then
    return
  end
  M.sync(buf)
  vim.api.nvim_buf_clear_namespace(buf, M.ns, 0, -1)
  local path = store.buf_path(buf)
  for _, comment in ipairs(store.data.comments) do
    if comment._buf == buf then
      comment._buf, comment._mark = nil, nil
    end
  end
  if not path then
    return
  end
  local count = vim.api.nvim_buf_line_count(buf)
  for _, comment in ipairs(store.for_path(path)) do
    local start_row = math.min(comment.start_line, count) - 1
    local end_row = math.max(start_row, math.min(comment.end_line, count) - 1)
    local hl = highlights[comment.state] or highlights.draft
    local range = comment.end_line > comment.start_line
        and string.format(' L%d-%d', comment.start_line, comment.end_line)
      or ''
    comment._mark = vim.api.nvim_buf_set_extmark(buf, M.ns, start_row, 0, {
      end_row = end_row,
      end_col = 0,
      sign_text = signs[comment.state] or signs.draft,
      sign_hl_group = hl,
      virt_text = {
        {
          string.format(
            '  %s %s%s: %s',
            comment.id,
            comment.state,
            range,
            first_line(comment.text)
          ),
          hl,
        },
      },
      virt_text_pos = 'eol',
      invalidate = true,
      undo_restore = true,
    })
    comment._buf = buf
  end
end

--- Re-render every loaded buffer, or only those showing `path`.
---@param path? string
function M.refresh(path)
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) then
      local buf_path = store.buf_path(buf)
      if buf_path and (path == nil or buf_path == path) then
        M.render(buf)
      end
    end
  end
  M.refresh_thread()
end

local function float_config(title, lines, footer)
  local width = 20
  for _, line in ipairs(lines) do
    width = math.max(width, vim.fn.strdisplaywidth(line))
  end
  width = math.min(math.max(width + 2, 60), math.floor(vim.o.columns * 0.8))
  local height = math.min(math.max(#lines, 6), math.floor(vim.o.lines * 0.6))
  return {
    relative = 'editor',
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2) - 1,
    col = math.floor((vim.o.columns - width) / 2),
    style = 'minimal',
    border = 'rounded',
    title = ' ' .. title .. ' ',
    footer = footer and (' ' .. footer .. ' ') or nil,
    footer_pos = footer and 'right' or nil,
  }
end

local editor_count = 0

--- Multi-line text input in a float. `:w` or <C-s> submits, `q` discards.
---@param opts { title: string, text?: string, on_submit: fun(text: string) }
function M.input(opts)
  editor_count = editor_count + 1
  local buf = vim.api.nvim_create_buf(false, true)
  local lines = vim.split(opts.text or '', '\n', { plain = true })
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_name(buf, 'claude-review://input/' .. editor_count)
  vim.bo[buf].buftype = 'acwrite'
  vim.bo[buf].bufhidden = 'wipe'
  vim.bo[buf].filetype = 'markdown'
  vim.bo[buf].modified = false
  local win = vim.api.nvim_open_win(
    buf,
    true,
    float_config(opts.title, lines, ':w / <C-s> submit · q discard')
  )
  vim.wo[win].wrap = true

  local function close()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end
  local function submit()
    local text =
      table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), '\n')
    text = vim.trim(text)
    vim.bo[buf].modified = false
    vim.cmd.stopinsert()
    close()
    if text == '' then
      vim.notify(
        'claude-review: empty text, nothing saved',
        vim.log.levels.WARN
      )
      return
    end
    opts.on_submit(text)
  end
  vim.api.nvim_create_autocmd(
    'BufWriteCmd',
    { buffer = buf, callback = submit }
  )
  vim.keymap.set(
    { 'n', 'i' },
    '<C-s>',
    submit,
    { buffer = buf, desc = 'Submit' }
  )
  vim.keymap.set('n', 'q', close, { buffer = buf, desc = 'Discard' })
  if opts.text == nil or opts.text == '' then
    vim.cmd.startinsert()
  end
end

local thread_view = nil ---@type { id: string, buf: integer, win: integer, actions: table }?

local function thread_lines(comment)
  local range = comment.end_line > comment.start_line
      and string.format('%d-%d', comment.start_line, comment.end_line)
    or tostring(comment.start_line)
  local lines = {
    string.format(
      '# %s · %s · %s:%s',
      comment.id,
      comment.state,
      comment.path,
      range
    ),
    '',
  }
  vim.list_extend(lines, vim.split(comment.text, '\n', { plain = true }))
  for _, entry in ipairs(comment.thread) do
    table.insert(lines, '')
    table.insert(
      lines,
      entry.from == 'claude' and '## Claude'
        or ('## You' .. (entry.pending and ' (not delivered yet)' or ''))
    )
    table.insert(lines, '')
    vim.list_extend(lines, vim.split(entry.text, '\n', { plain = true }))
  end
  return lines
end

local function fill_thread(comment)
  local view = assert(thread_view)
  vim.bo[view.buf].modifiable = true
  vim.api.nvim_buf_set_lines(view.buf, 0, -1, false, thread_lines(comment))
  vim.bo[view.buf].modifiable = false
  vim.bo[view.buf].modified = false
end

--- Read-only thread view. `actions` maps keys to functions of the comment.
---@param comment table
---@param actions table<string, { desc: string, fn: fun(comment: table) }>
function M.show_thread(comment, actions)
  M.close_thread()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = 'wipe'
  vim.bo[buf].filetype = 'markdown'
  local lines = thread_lines(comment)
  local hints = { 'q close' }
  for key, action in pairs(actions) do
    table.insert(hints, key .. ' ' .. action.desc)
  end
  table.sort(hints)
  local win = vim.api.nvim_open_win(
    buf,
    true,
    float_config('Claude review', lines, table.concat(hints, ' · '))
  )
  vim.wo[win].wrap = true
  thread_view = { id = comment.id, buf = buf, win = win, actions = actions }
  fill_thread(comment)
  vim.keymap.set('n', 'q', M.close_thread, { buffer = buf, desc = 'Close' })
  for key, action in pairs(actions) do
    vim.keymap.set('n', key, function()
      local current = store.get(comment.id)
      if current then
        action.fn(current)
      end
    end, { buffer = buf, desc = action.desc })
  end
  vim.api.nvim_create_autocmd('BufWipeout', {
    buffer = buf,
    once = true,
    callback = function()
      if thread_view and thread_view.buf == buf then
        thread_view = nil
      end
    end,
  })
end

function M.close_thread()
  if thread_view and vim.api.nvim_win_is_valid(thread_view.win) then
    vim.api.nvim_win_close(thread_view.win, true)
  end
  thread_view = nil
end

--- Redraw the open thread view, e.g. after a reply arrived.
function M.refresh_thread()
  if not thread_view or not vim.api.nvim_buf_is_valid(thread_view.buf) then
    return
  end
  local comment = store.get(thread_view.id)
  if comment then
    fill_thread(comment)
  else
    M.close_thread()
  end
end

return M
