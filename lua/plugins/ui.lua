return {

  {
    'ron-rs/ron.vim',
  },

  {
    'dstein64/vim-startuptime',
    lazy = false,
  },

  {
    'willothy/flatten.nvim',
    opts = {},
  },

  {
    'stevearc/dressing.nvim',
    opts = {},
  },

  {
    'j-hui/fidget.nvim',
    event = 'BufReadPost',
    tag = 'legacy',
    opts = {
      window = { blend = 0 },
    },
  },

  {
    'MeanderingProgrammer/render-markdown.nvim',
    dependencies = {
      'echasnovski/mini.icons',
      'nvim-treesitter/nvim-treesitter',
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
        { 's',      mode = 'n' },
      },
    },
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

        on_highlights = function(highlights, c)
          highlights['TabLine'] =
          { fg = c.polar_night.light, bg = c.polar_night.bright }
          highlights['TabLineSel'] = { fg = c.frost.ice, bg = c.fg_gutter }
          highlights['@lsp.typemod.variable.readonly.cpp'] =
          { undercurl = true }
        end,
      })
      require('nord').load()
    end,
  },
}
