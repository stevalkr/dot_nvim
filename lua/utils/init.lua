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

return M
