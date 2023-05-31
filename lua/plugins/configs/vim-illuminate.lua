local M = {}

M.config = function(_, _opts)
  local kopts = { noremap = true, silent = true }
  vim.keymap.set('n', '[[', function()
    require('illuminate').goto_prev_reference()
  end, kopts)
  vim.keymap.set('n', ']]', function()
    require('illuminate').goto_next_reference()
  end, kopts)
end

return M
