local utils = require('utils')
return {

  'ThePrimeagen/refactoring.nvim',
  ft = { 'c', 'cpp', 'go', 'javascript', 'lua', 'python', 'typescript' },
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-treesitter/nvim-treesitter',
  },

  config = function()
    local refactoring = require('refactoring')
    refactoring.setup({})

    utils.keymap('x', '<leader>rf', ':Refactor extract ', 'Extract function')
    utils.keymap('n', '<leader>rI', ':Refactor inline_func', 'Inline function')
    utils.keymap('x', '<leader>re', ':Refactor extract_var ', 'Extract variable')
    utils.keymap({ 'n', 'x' }, '<leader>ri', ':Refactor inline_var', 'Inline variable')

    utils.keymap('n', '<leader>rc', function() refactoring.debug.cleanup({}) end, 'Cleanup debug statements')
    utils.keymap('n', '<leader>rp', function() refactoring.debug.printf({ below = false }) end,
      'Print debug statements')
    utils.keymap({ 'x', 'n' }, '<leader>rv', function() refactoring.debug.print_var() end, 'Print debug variable')
  end

}
