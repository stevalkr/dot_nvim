local M = {}

M.treesitter_fold = function()
  vim.opt.foldenable = false
  vim.opt.foldmethod = 'expr'
  vim.opt.foldexpr = 'nvim_treesitter#foldexpr()'
end

vim.api.nvim_create_user_command('TSFold',
  M.treesitter_fold,
  { nargs = 0 }
)

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

M.foldtext = function()
  local line = vim.fn.getline(vim.v.foldstart)
  local line_count = vim.v.foldend - vim.v.foldstart + 1
  return line .. "  <- " .. line_count .. " lines "
end

M.delete_hidden_buffers = function()
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
end

vim.api.nvim_create_user_command('DeleteHiddenBuf',
  M.delete_hidden_buffers,
  { nargs = 0 }
)

return M
