local M = {}

---@param t table
---@return string
M.dump = function(t)
  if type(t) == 'table' then
    local s = '{ '
    for k, v in pairs(t) do
      if type(k) ~= 'number' then k = '"' .. k .. '"' end
      s = s .. '[' .. k .. '] = ' .. M.dump(v) .. ','
    end
    return s .. '} '
  else
    return tostring(t)
  end
end

M.capitalize = function()
  local hlsearch = vim.v.hlsearch
  vim.cmd([[execute "normal! \<Esc>"]])
  vim.cmd([[s/\%V\<.\%V/\u&/g]])
  vim.fn.histdel('/', -1)
  vim.fn.setreg('/', vim.fn.histget('/', -1))
  vim.v.hlsearch = hlsearch
end

---@param key string
M.smart_delete = function(key)
  vim.cmd.normal({ (vim.fn.getline('.'):match("^%s*$") and '"_' or "") .. key, bang = true })
end

-- used for wezterm scrollback
M.colorize = function()
  local buf = vim.api.nvim_get_current_buf()

  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  while #lines > 0 and vim.trim(lines[#lines]) == '' do
    lines[#lines] = nil
  end
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, {})

  vim.b[buf].minianimate_disable = true

  vim.api.nvim_chan_send(vim.api.nvim_open_term(buf, {}), table.concat(lines, '\r\n'))
  vim.keymap.set('n', 'q', '<cmd>qa!<cr>', { silent = true, buffer = buf })
  vim.api.nvim_create_autocmd('TextChanged', { buffer = buf, command = 'normal! G$' })
  vim.api.nvim_create_autocmd('TermEnter', { buffer = buf, command = 'stopinsert' })

  vim.wo.relativenumber = false
  vim.wo.statuscolumn = ''
  vim.wo.signcolumn = 'no'
  vim.opt.listchars = { space = ' ' }

  vim.defer_fn(function()
    vim.b[buf].minianimate_disable = false
  end, 2000)
end

---@param name string
---@return boolean
M.has_plugin = function(name)
  for _, plugin in ipairs(require('lazy').plugins()) do
    if plugin.name == name then
      return true
    end
  end
  return false
end

---@generic T: table
---@param mode string|table
---@param lhs string
---@param rhs function|string
---@param desc string
---@param opts? T
M.keymap = function(mode, lhs, rhs, desc, opts)
  vim.validate('mode', mode, { 'string', 'table' })
  vim.validate('lhs', lhs, 'string')
  vim.validate('rhs', rhs, { 'string', 'function' })
  vim.validate('desc', desc, 'string')
  vim.validate('opts', opts, 'table', true)

  opts = vim.deepcopy(opts or {})
  opts = vim.tbl_deep_extend('force', { desc = desc, remap = false, silent = true }, opts)

  vim.keymap.set(mode, lhs, rhs, opts)
end

M.save_session = function()
  if not M.has_plugin('mini.sessions') then
    vim.notify('Plugin mini.sessions is not installed', vim.log.levels.ERROR)
    return false
  end
  local function buffer_filter(buf)
    if not vim.api.nvim_buf_is_valid(buf) or not vim.api.nvim_get_option_value('buflisted', { buf = buf }) then
      return false
    end
    return true
  end

  local buffers = vim.tbl_filter(buffer_filter, vim.api.nvim_list_bufs())

  local non_hidden_buffer = {}
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    non_hidden_buffer[vim.api.nvim_win_get_buf(win)] = true
  end

  for _, buffer in ipairs(buffers) do
    if non_hidden_buffer[buffer] == nil then
      if vim.api.nvim_get_option_value('modified', { buf = buffer }) then
        vim.notify(
          string.format('No write since last change for buffer %d', buffer), vim.log.levels.WARN
        )
      else
        vim.cmd('bdelete ' .. buffer)
      end
    end
  end

  vim.uv.fs_mkdir('.cache', 493, function(err) -- 0755
    -- Ignore if the directory already exists
    if err and not err:match('^EEXIST:') then
      vim.api.notify(err, vim.log.levels.ERROR)
    end
  end)

  require('mini.sessions').write('.cache/session.vim')
end

---@class AutocmdDefinition
---@field event string|table
---@field pattern? string|table
---@field command? string
---@field callback? string|fun(opts: table)
---@param definitions table<string, AutocmdDefinition[]>
M.augroup = function(definitions)
  for group_name, definition in pairs(definitions) do
    vim.api.nvim_create_augroup(group_name, { clear = true })
    for _, def in ipairs(definition) do
      vim.api.nvim_create_autocmd(def.event, {
        pattern = def.pattern,
        group = group_name,
        command = def.command,
        callback = def.callback
      })
    end
  end
end


return M
