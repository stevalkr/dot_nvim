-- Comment model and `.cache/claude-review/comments.json` persistence.
--
-- A comment is `{ id, path, start_line, end_line, text, state, acked, thread }`
-- where `thread` holds `{ from = 'user'|'claude', text, id?, pending? }`.
-- Fields starting with `_` (extmark bookkeeping) are never written to disk.
local M = {}

M.states = { 'draft', 'sent', 'delivered', 'replied', 'resolved' }

---@type string
M.root = nil
M.data = { version = 1, next_id = 1, comments = {} }

local function file_path()
  return vim.fs.joinpath(M.root, '.cache', 'claude-review', 'comments.json')
end

---@param root string
function M.load(root)
  M.root = root
  M.data = { version = 1, next_id = 1, comments = {} }
  local fd = io.open(file_path(), 'r')
  if not fd then
    return
  end
  local content = fd:read('*a')
  fd:close()
  local ok, data = pcall(vim.json.decode, content)
  if not ok or type(data) ~= 'table' or type(data.comments) ~= 'table' then
    vim.notify(
      'claude-review: ignoring unreadable ' .. file_path(),
      vim.log.levels.WARN
    )
    return
  end
  M.data.next_id = tonumber(data.next_id) or 1
  for _, comment in ipairs(data.comments) do
    comment.thread = comment.thread or {}
    table.insert(M.data.comments, comment)
  end
end

local function serializable(comment)
  local copy = {}
  for key, value in pairs(comment) do
    if type(key) ~= 'string' or key:sub(1, 1) ~= '_' then
      copy[key] = vim.deepcopy(value)
    end
  end
  return copy
end

function M.save()
  if not M.root then
    return
  end
  local path = file_path()
  local comments = vim.tbl_map(serializable, M.data.comments)
  if #comments == 0 and not vim.uv.fs_stat(path) then
    return
  end
  vim.fn.mkdir(vim.fs.dirname(path), 'p')
  local tmp = path .. '.tmp'
  local fd, err = io.open(tmp, 'w')
  if not fd then
    vim.notify(
      'claude-review: cannot write ' .. tostring(err),
      vim.log.levels.ERROR
    )
    return
  end
  fd:write(vim.json.encode({
    version = 1,
    next_id = M.data.next_id,
    comments = comments,
  }))
  fd:close()
  vim.uv.fs_rename(tmp, path)
end

---@param name string Absolute or relative file name.
---@return string Path relative to the root when inside it, else absolute.
function M.relative(name)
  local abs = vim.fs.normalize(vim.fs.abspath(name))
  return vim.fs.relpath(M.root, abs) or abs
end

---@param path string
---@return string
function M.absolute(path)
  if vim.startswith(path, '/') then
    return path
  end
  return vim.fs.joinpath(M.root, path)
end

---@param buf integer
---@return string?
function M.buf_path(buf)
  if vim.bo[buf].buftype ~= '' then
    return nil
  end
  local name = vim.api.nvim_buf_get_name(buf)
  if name == '' then
    return nil
  end
  return M.relative(name)
end

function M.add(path, start_line, end_line, text)
  local comment = {
    id = 'c' .. M.data.next_id,
    path = path,
    start_line = start_line,
    end_line = math.max(start_line, end_line),
    text = text,
    state = 'draft',
    acked = false,
    thread = {},
    created = os.time(),
  }
  M.data.next_id = M.data.next_id + 1
  table.insert(M.data.comments, comment)
  return comment
end

--- Find a comment by its id or by the id of one of its thread messages.
---@return table? comment, table? entry
function M.get(id)
  for _, comment in ipairs(M.data.comments) do
    if comment.id == id then
      return comment, nil
    end
    for _, entry in ipairs(comment.thread) do
      if entry.id == id then
        return comment, entry
      end
    end
  end
end

function M.remove(id)
  for i, comment in ipairs(M.data.comments) do
    if comment.id == id then
      table.remove(M.data.comments, i)
      return comment
    end
  end
end

---@param filter? fun(comment: table): boolean
function M.list(filter)
  local result = {}
  for _, comment in ipairs(M.data.comments) do
    if not filter or filter(comment) then
      table.insert(result, comment)
    end
  end
  return result
end

function M.for_path(path)
  return M.list(function(comment)
    return comment.path == path
  end)
end

--- Append a follow-up from the user; returns the thread entry to send.
function M.follow_up(comment, text)
  local entry = {
    from = 'user',
    id = comment.id .. '.' .. (#comment.thread + 1),
    text = text,
    pending = true,
  }
  table.insert(comment.thread, entry)
  comment.state = 'sent'
  return entry
end

--- Messages Neovim sent but the bridge never acknowledged.
---@return table[] payloads
function M.unacked()
  local result = {}
  for _, comment in ipairs(M.data.comments) do
    if comment.state ~= 'draft' then
      if not comment.acked then
        table.insert(result, M.payload(comment))
      end
      for _, entry in ipairs(comment.thread) do
        if entry.pending then
          table.insert(result, M.payload(comment, entry))
        end
      end
    end
  end
  return result
end

function M.payload(comment, entry)
  return {
    type = 'comment',
    id = entry and entry.id or comment.id,
    thread_id = entry and comment.id or nil,
    path = comment.path,
    start_line = comment.start_line,
    end_line = comment.end_line,
    text = entry and entry.text or comment.text,
  }
end

---@return table? comment
function M.ack(id)
  local comment, entry = M.get(id)
  if not comment then
    return nil
  end
  if entry then
    entry.pending = nil
  else
    comment.acked = true
  end
  local pending = vim.iter(comment.thread):any(function(e)
    return e.pending
  end)
  if comment.state == 'sent' and comment.acked and not pending then
    comment.state = 'delivered'
  end
  return comment
end

---@return table? comment
function M.reply(id, text, resolve)
  local comment = M.get(id)
  if not comment then
    return nil
  end
  table.insert(comment.thread, { from = 'claude', text = text })
  comment.acked = true
  comment.state = resolve and 'resolved' or 'replied'
  return comment
end

return M
