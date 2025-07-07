local utils = require('utils')
-- return {
--
--   'ThePrimeagen/refactoring.nvim',
--   dev = true,
--   ft = { 'c', 'cpp', 'rust', 'go', 'javascript', 'lua', 'python', 'typescript' },
--   dependencies = {
--     'nvim-lua/plenary.nvim',
--     'nvim-treesitter/nvim-treesitter',
--   },
--
--   config = function()
--     local refactoring = require('refactoring')
--     refactoring.setup({})
--
--     utils.keymap('x', '<leader>rf', ':Refactor extract ', 'Extract function')
--     utils.keymap('n', '<leader>rI', ':Refactor inline_func', 'Inline function')
--     utils.keymap('x', '<leader>re', ':Refactor extract_var ', 'Extract variable')
--     utils.keymap({ 'n', 'x' }, '<leader>ri', ':Refactor inline_var', 'Inline variable')
--
--     utils.keymap('n', '<leader>rc', function() refactoring.debug.cleanup({}) end, 'Cleanup debug statements')
--     utils.keymap('n', '<leader>rp', function() refactoring.debug.printf({ below = false }) end,
--       'Print debug statements')
--     utils.keymap({ 'x', 'n' }, '<leader>rv', function() refactoring.debug.print_var() end, 'Print debug variable')
--   end
--
-- }

-- return {
--
--   'chrisgrieser/nvim-chainsaw',
--   dev = true,
--   event = 'VeryLazy',
--   config = function()
--     require('chainsaw').setup({})
--     utils.keymap({ 'n', 'v' }, '<leader>rc', function()
--       require('chainsaw').removeLogs()
--     end, 'Cleanup debug statements')
--
--     utils.keymap('n', '<leader>rp', function()
--       require('chainsaw').messageLog()
--     end, 'Print message log')
--
--     utils.keymap('n', '<leader>rP', function()
--       require('chainsaw').messageLog({ below = false })
--     end, 'Print message log')
--
--     utils.keymap({ 'n', 'v' }, '<leader>rv', function()
--       require('chainsaw').variableLog()
--     end, 'Print variable log')
--
--     utils.keymap({ 'n', 'v' }, '<leader>rV', function()
--       require('chainsaw').variableLog({ below = false })
--     end, 'Print variable log')
--
--     utils.keymap('n', '<leader>rs', function()
--       require('chainsaw').sound()
--     end, 'Print sound')
--
--     utils.keymap('n', '<leader>rS', function()
--       require('chainsaw').stacktraceLog({ below = false })
--     end, 'Print stacktrace log')
--
--     utils.keymap('n', '<leader>rt', function()
--       require('chainsaw').timeLog({ below = false })
--     end, 'Print time log')
--
--     utils.keymap('n', '<leader>rr', function()
--       require('chainsaw').emojiLog({ below = false })
--     end, 'Print emoji log')
--
--     utils.keymap({ 'n', 'v' }, '<leader>ra', function()
--       require('chainsaw').assertLog({ below = false })
--     end, 'Print assert log')
--   end,
-- }

return {

  'andrewferrier/debugprint.nvim',
  lazy = false,
  dependencies = {
    'echasnovski/mini.hipatterns',
    'ibhagwan/fzf-lua',
  },

  opts = {
    keymaps = {
      normal = {
        plain_below = '<leader>rp',
        plain_above = '<leader>rP',
        variable_below = '<leader>rv',
        variable_above = '<leader>rV',
        surround_plain = '<leader>rsp',
        surround_variable = '<leader>rsv',
        textobj_below = '<leader>ro',
        textobj_above = '<leader>rO',
        textobj_surround = '<leader>rso',
        toggle_comment_debug_prints = '<leader>rc',
        delete_debug_prints = '<leader>rd',
      },
      visual = {
        variable_below = '<leader>rv',
        variable_above = '<leader>rV',
      },
    },
    print_tag = '🪵',
  },
}
