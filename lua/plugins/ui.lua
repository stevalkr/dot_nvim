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
        { 's', mode = 'n' }
      },
    }
  },

  {
    "OXY2DEV/markview.nvim",
    ft = { "markdown" },
    dependencies = {
      "nvim-tree/nvim-web-devicons",
      "nvim-treesitter/nvim-treesitter"
    }
  },

  {
    "iamcco/markdown-preview.nvim",
    ft = { "markdown" },
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    build = function() vim.fn["mkdp#util#install"]() end,
  },

  {
    'mikesmithgh/kitty-scrollback.nvim',
    lazy = true,
    version = '*',
    event = { 'User KittyScrollbackLaunch' },
    cmd = { 'KittyScrollbackGenerateKittens', 'KittyScrollbackCheckHealth' },
    opts = { {
      restore_options = true,
      status_window = {
        style_simple = true,
      }
    } }
  }

}
