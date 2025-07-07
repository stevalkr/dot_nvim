local utils = require('utils')
return {

  'folke/flash.nvim',
  event = 'VeryLazy',

  config = function()
    local flash = require('flash')
    flash.setup({
      modes = {
        char = {
          keys = { 'f', 'F', 't', 'T' },
        },
      },
    })
    utils.keymap({ 'n', 'x', 'o' }, 'm', flash.jump, 'Flash')
    utils.keymap({ 'n', 'x', 'o' }, 'S', flash.treesitter, 'Flash Treesitter')
    utils.keymap('o', 'r', flash.remote, 'Remote Flash')
    utils.keymap(
      { 'o', 'x' },
      'R',
      flash.treesitter_search,
      'Treesitter Search'
    )
    utils.keymap('c', '<C-s>', flash.toggle, 'Toggle Flash Search')
  end,
}
