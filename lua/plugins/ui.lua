local utils = require('utils')

return {

  {
    'dstein64/vim-startuptime',
    lazy = false
  },

  {
    'j-hui/fidget.nvim',
    event = 'BufReadPost',
    tag = 'legacy',
    opts = {
      window = { blend = 0 },
    }
  },

  {
    'willothy/flatten.nvim',
    opts = {}
  },

  {
    'gbprod/nord.nvim',
    config = function()
      require('nord').setup({
        transparent = vim.g.neovide == nil,
        terminal_colors = true,
        diff = { mode = 'bg' },
        borders = true,
        errors = { mode = 'bg' },
        search = { theme = 'vim' },
        styles = {
          comments = { italic = true },
          keywords = {},
          functions = {},
          variables = {},
        },

        on_highlights = function(highlights, colors)
          highlights['@lsp.typemod.variable.readonly.cpp'] = { undercurl = true }
        end,
      })
      require('nord').load()
    end
  },

  {
    'folke/which-key.nvim',
    event = 'VeryLazy',
    init = function()
      vim.o.timeout = true
      vim.o.timeoutlen = 300
    end,
    opts = {
      triggers = {
        { '<auto>', mode = 'nxsot' },
        { 's',      mode = 'n' }
      },
    }
  },

  {
    'stevearc/dressing.nvim',
    opts = {},
  },

  {
    'MeanderingProgrammer/render-markdown.nvim',
    dependencies = { 'nvim-treesitter/nvim-treesitter', 'echasnovski/mini.icons' },
    ---@module 'render-markdown'
    ---@type render.md.UserConfig
    opts = {},
  },

  {
    'mrjones2014/smart-splits.nvim',
    config = function()
      local smart_splits = require('smart-splits')
      smart_splits.setup({
        cursor_follows_swapped_bufs = true,
        default_amount = 1,
        at_edge = 'stop'
      })
      utils.keymap('n', '<Left>', smart_splits.resize_left, 'resize left')
      utils.keymap('n', '<Down>', smart_splits.resize_down, 'resize down')
      utils.keymap('n', '<Up>', smart_splits.resize_up, 'resize up')
      utils.keymap('n', '<Right>', smart_splits.resize_right, 'resize right')
      -- utils.keymap('n', '<leader>h', smart_splits.start_resize_mode, 'split left')

      utils.keymap('n', '<C-h>', smart_splits.move_cursor_left, 'move cursor left')
      utils.keymap('n', '<C-j>', smart_splits.move_cursor_down, 'move cursor down')
      utils.keymap('n', '<C-k>', smart_splits.move_cursor_up, 'move cursor up')
      utils.keymap('n', '<C-l>', smart_splits.move_cursor_right, 'move cursor right')
      -- utils.keymap('n', '<C-\\>', smart_splits.move_cursor_previous, 'move cursor previous')
      utils.keymap('n', '<C-S-h>', smart_splits.resize_left, 'resize left')
      utils.keymap('n', '<C-S-j>', smart_splits.resize_down, 'resize down')
      utils.keymap('n', '<C-S-k>', smart_splits.resize_up, 'resize up')
      utils.keymap('n', '<C-S-l>', smart_splits.resize_right, 'resize right')

      utils.keymap('n', 'sH', smart_splits.swap_buf_left, 'swap buffer left')
      utils.keymap('n', 'sJ', smart_splits.swap_buf_down, 'swap buffer down')
      utils.keymap('n', 'sK', smart_splits.swap_buf_up, 'swap buffer up')
      utils.keymap('n', 'sL', smart_splits.swap_buf_right, 'swap buffer right')
    end
  }

}
