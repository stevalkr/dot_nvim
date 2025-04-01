local utils = require('utils')
return {

  {
    'dstein64/vim-startuptime',
    lazy = false
  },

  {
    'willothy/flatten.nvim',
    opts = {}
  },

  {
    'stevearc/dressing.nvim',
    opts = {},
  },

  {
    "3rd/image.nvim",
    enabled = vim.env.TMUX == nil,    -- https://github.com/3rd/image.nvim/issues/279
    init = function()
      if vim.env.HOMEBREW_PREFIX then -- TODO
        vim.fn.setenv('PKG_CONFIG_PATH_FOR_TARGET',
          string.format('%s:%s/lib/pkgconfig:%s/share/pkgconfig', (vim.env.PKG_CONFIG_PATH_FOR_TARGET or ''),
            vim.env.HOMEBREW_PREFIX, vim.env.HOMEBREW_PREFIX
          ))
      end
    end,
    opts = {}
  },

  {
    'HakonHarnes/img-clip.nvim',
    event = 'VeryLazy',
    opts = {}
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
    'MeanderingProgrammer/render-markdown.nvim',
    dependencies = {
      'echasnovski/mini.icons',
      'nvim-treesitter/nvim-treesitter'
    },
    opts = {},
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

        on_highlights = function(highlights, _)
          highlights['@lsp.typemod.variable.readonly.cpp'] = { undercurl = true }
        end,
      })
      require('nord').load()
    end
  },

  {
    'stevalkr/multiplexer.nvim',
    lazy = false,
    dev = true,
    opts = {
      default_resize_amount = 5,
      on_init = function()
        local multiplexer = require('multiplexer')

        vim.keymap.set('n', '<C-h>', multiplexer.activate_pane_left, { desc = 'Activate pane to the left' })
        vim.keymap.set('n', '<C-j>', multiplexer.activate_pane_down, { desc = 'Activate pane below' })
        vim.keymap.set('n', '<C-k>', multiplexer.activate_pane_up, { desc = 'Activate pane above' })
        vim.keymap.set('n', '<C-l>', multiplexer.activate_pane_right, { desc = 'Activate pane to the right' })

        vim.keymap.set('n', '<C-S-h>', multiplexer.resize_pane_left, { desc = 'Resize pane to the left' })
        vim.keymap.set('n', '<C-S-j>', multiplexer.resize_pane_down, { desc = 'Resize pane below' })
        vim.keymap.set('n', '<C-S-k>', multiplexer.resize_pane_up, { desc = 'Resize pane above' })
        vim.keymap.set('n', '<C-S-l>', multiplexer.resize_pane_right, { desc = 'Resize pane to the right' })
      end
    }
  }

}
