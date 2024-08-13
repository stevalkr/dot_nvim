local utils = require('utils')

return {

  {
    'folke/lazy.nvim',
    version = '*'
  },

  {
    'dstein64/vim-startuptime',
    lazy = false,
    enabled = true
  },

  {
    'folke/flash.nvim',
    event = 'VeryLazy',
    opts = {
      modes = {
        char = {
          keys = { 'f', 'F', 't', 'T' }
        }
      }
    },
    -- stylua: ignore
    keys = {
      { 'm',     mode = { 'n', 'x', 'o' }, function() require('flash').jump() end,              desc = 'Flash' },
      { 'S',     mode = { 'n', 'x', 'o' }, function() require('flash').treesitter() end,        desc = 'Flash Treesitter' },
      { 'r',     mode = 'o',               function() require('flash').remote() end,            desc = 'Remote Flash' },
      { 'R',     mode = { 'o', 'x' },      function() require('flash').treesitter_search() end, desc = 'Treesitter Search' },
      { '<C-s>', mode = { 'c' },           function() require('flash').toggle() end,            desc = 'Toggle Flash Search' },
    },
  },

  {
    'echasnovski/mini.ai',
    version = '*',
    event = 'VeryLazy',
    opts = {
      mappings = {
        goto_left = '[[',
        goto_right = ']]',
      }
    }
  },

  {
    'echasnovski/mini.pairs',
    version = '*',
    event = 'VeryLazy',
    opts = {},
  },

  {
    'echasnovski/mini.surround',
    version = '*',
    event = 'VeryLazy',
    opts = {},
  },

  {
    'echasnovski/mini.indentscope',
    version = '*',
    event = 'VeryLazy',
    opts = function(_, _opts)
      return {
        draw = {
          animation = require('mini.indentscope').gen_animation.none()
        },
        options = {
          try_as_border = true
        }
      }
    end
  },

  {
    'echasnovski/mini.cursorword',
    version = '*',
    event = { 'BufReadPost', 'BufNewFile' },
    opts = {
      delay = 100,
    }
  },

  {
    'echasnovski/mini.sessions',
    version = '*',
    opts = {
      autoread = true,
      autowrite = false,
      file = '.cache/session.vim',
      directory = '',
      force = { read = false, write = true, delete = true },
    }
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
    lazy = false,
    opts = {
      window = {
        open = 'tab'
      },
      nest_if_no_args = true,
      one_per = {
        kitty = true,
      },
    },
  },

  {
    'gbprod/nord.nvim',
    config = function()
      require('nord').setup({
        transparent = true,
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
    opts = {}
  },

  {
    "iamcco/markdown-preview.nvim",
    ft = { "markdown" },
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    build = function() vim.fn["mkdp#util#install"]() end,
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
    'mikesmithgh/kitty-scrollback.nvim',
    lazy = true,
    version = '*',
    enabled = (vim.env.KITTY_SCROLLBACK_NVIM == 'true'),
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
