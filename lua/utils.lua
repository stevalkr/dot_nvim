local M = {}

M.dump = function(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. M.dump(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end

M.has_plugin = function(name)
  for _, plugin in ipairs(require('lazy').plugins()) do
    if plugin.name == name then
      return true
    end
  end
  return false
end

M.foldtext = function()
  local line = vim.fn.getline(vim.v.foldstart)
  local line_count = vim.v.foldend - vim.v.foldstart + 1
  return line .. "  <- " .. line_count .. " lines "
end

M.keymap = function(mode, lhs, rhs, desc, opts)
  vim.validate({
    mode = { mode, { 's', 't' } },
    lhs = { lhs, 's' },
    rhs = { rhs, { 's', 'f' } },
    desc = { desc, 's' },
    opts = { opts, 't', true }
  })

  opts = vim.deepcopy(opts) or {}
  opts = vim.tbl_deep_extend('force', { desc = desc, remap = false, silent = true }, opts)

  vim.keymap.set(mode, lhs, rhs, opts)
end

M.key = function(mode, lhs, rhs, desc, opts)
  vim.validate({
    mode = { mode, { 's', 't' } },
    lhs = { lhs, 's' },
    rhs = { rhs, 's' },
    desc = { desc, 's' },
    opts = { opts, 't', true }
  })

  opts = vim.deepcopy(opts) or {}
  opts = vim.tbl_deep_extend('force', {
    [1] = lhs, [2] = rhs, mode = mode, desc = desc, remap = false, silent = true
  }, opts)

  return opts
end

M.save_session = function()
  local function buffer_filter(buf)
    if not vim.api.nvim_buf_is_valid(buf) or not vim.api.nvim_buf_get_option(buf, 'buflisted') then
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
      if vim.api.nvim_buf_get_option(buffer, 'modified') then
        vim.api.nvim_err_writeln(
          string.format('No write since last change for buffer %d', buffer)
        )
      else
        vim.cmd('bdelete ' .. buffer)
      end
    end
  end

  require('mini.sessions').write('.cache/session.vim')
end

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
