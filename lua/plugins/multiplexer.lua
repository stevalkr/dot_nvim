return {

  'stevalkr/multiplexer.nvim',
  lazy = false,
  dev = true,
  opts = {
    default_resize_amount = 5,
    on_init = function()
      local multiplexer = require('multiplexer')

      vim.keymap.set(
        { 'n', 'i' },
        '<C-h>',
        multiplexer.activate_pane_left,
        { desc = 'Activate pane to the left' }
      )
      vim.keymap.set(
        { 'n', 'i' },
        '<C-j>',
        multiplexer.activate_pane_down,
        { desc = 'Activate pane below' }
      )
      vim.keymap.set(
        { 'n', 'i' },
        '<C-k>',
        multiplexer.activate_pane_up,
        { desc = 'Activate pane above' }
      )
      vim.keymap.set(
        { 'n', 'i' },
        '<C-l>',
        multiplexer.activate_pane_right,
        { desc = 'Activate pane to the right' }
      )

      vim.keymap.set(
        { 'n', 'i' },
        '<C-S-h>',
        multiplexer.resize_pane_left,
        { desc = 'Resize pane to the left' }
      )
      vim.keymap.set(
        { 'n', 'i' },
        '<C-S-j>',
        multiplexer.resize_pane_down,
        { desc = 'Resize pane below' }
      )
      vim.keymap.set(
        { 'n', 'i' },
        '<C-S-k>',
        multiplexer.resize_pane_up,
        { desc = 'Resize pane above' }
      )
      vim.keymap.set(
        { 'n', 'i' },
        '<C-S-l>',
        multiplexer.resize_pane_right,
        { desc = 'Resize pane to the right' }
      )
    end,
  },
}
