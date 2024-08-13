local utils = require('utils')
return {

  'github/copilot.vim',
  build = ':Copilot setup',
  event = { 'BufReadPost' },

  config = function()
    vim.g.copilot_no_tab_map = true
    utils.keymap('i', '<C-CR>', 'copilot#Accept("\\<CR>")', 'Copilot', { expr = true, replace_keycodes = false })
  end

}
