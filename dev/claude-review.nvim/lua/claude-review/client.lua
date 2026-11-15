-- Unix socket client for the bridge owner: newline-delimited JSON, reconnects
-- with backoff until `disconnect()`.
local M = {}

local PROTOCOL_VERSION = 1
local MIN_DELAY, MAX_DELAY = 500, 10000

local state = {
  path = nil, ---@type string?
  pipe = nil, ---@type uv.uv_pipe_t?
  connected = false,
  wanted = false,
  delay = MIN_DELAY,
  timer = nil, ---@type uv.uv_timer_t?
  generation = 0,
}

---@type fun(message: table)
M.on_message = function() end
---@type fun()
M.on_connect = function() end
---@type fun()
M.on_disconnect = function() end

function M.connected()
  return state.connected
end

function M.path()
  return state.path
end

local function close_pipe()
  local pipe = state.pipe
  state.pipe = nil
  local was_connected = state.connected
  state.connected = false
  if pipe and not pipe:is_closing() then
    pipe:read_stop()
    pipe:close()
  end
  return was_connected
end

local schedule_retry

local function attempt()
  if not state.wanted or state.pipe or not state.path then
    return
  end
  state.generation = state.generation + 1
  local generation = state.generation
  local pipe = assert(vim.uv.new_pipe(false))
  state.pipe = pipe
  pipe:connect(state.path, function(err)
    if generation ~= state.generation then
      return
    end
    if err then
      close_pipe()
      schedule_retry()
      return
    end
    state.delay = MIN_DELAY
    local buffer = ''
    pipe:read_start(function(read_err, chunk)
      if generation ~= state.generation then
        return
      end
      if read_err or not chunk then
        vim.schedule(function()
          if generation ~= state.generation then
            return
          end
          close_pipe()
          M.on_disconnect()
          schedule_retry()
        end)
        return
      end
      buffer = buffer .. chunk
      while true do
        local index = buffer:find('\n', 1, true)
        if not index then
          break
        end
        local line = buffer:sub(1, index - 1)
        buffer = buffer:sub(index + 1)
        local ok, message = pcall(vim.json.decode, line, {
          luanil = { object = true, array = true },
        })
        if ok and type(message) == 'table' then
          vim.schedule(function()
            M.on_message(message)
          end)
        end
      end
    end)
    vim.schedule(function()
      if generation ~= state.generation then
        return
      end
      -- Connected only from here, so nothing is written before the hello.
      state.connected = true
      M.send({ type = 'hello', role = 'nvim', version = PROTOCOL_VERSION })
      M.on_connect()
    end)
  end)
end

schedule_retry = function()
  if not state.wanted then
    return
  end
  if not state.timer then
    state.timer = assert(vim.uv.new_timer())
  end
  local delay = state.delay
  state.delay = math.min(state.delay * 2, MAX_DELAY)
  state.timer:stop()
  state.timer:start(delay, 0, vim.schedule_wrap(attempt))
end

--- Connect to `path` (or the current path), retrying until it succeeds.
---@param path? string
function M.connect(path)
  if path and path ~= state.path then
    M.close()
    state.path = path
  end
  state.wanted = true
  if state.timer then
    state.timer:stop()
  end
  if not state.pipe then
    state.delay = MIN_DELAY
    attempt()
  end
end

--- Drop the connection without telling the owner (used on path changes).
function M.close()
  state.generation = state.generation + 1
  if state.timer then
    state.timer:stop()
  end
  if close_pipe() then
    M.on_disconnect()
  end
end

--- Stop for good: `bye` makes a monitor-mode listener exit.
---@param bye boolean
function M.disconnect(bye)
  state.wanted = false
  if bye and state.connected then
    M.send({ type = 'bye' })
  end
  M.close()
end

---@param message table
---@return boolean sent
function M.send(message)
  if not state.connected or not state.pipe then
    return false
  end
  state.pipe:write(vim.json.encode(message) .. '\n')
  return true
end

return M
