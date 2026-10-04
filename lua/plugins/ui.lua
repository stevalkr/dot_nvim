return {
  { src = 'https://github.com/ron-rs/ron.vim' },
  {
    src = 'https://github.com/dstein64/vim-startuptime',
    init = function()
      vim.g.startuptime_exe_path = vim.v.progpath
      vim.g.startuptime_exe_args = {
        '--cmd',
        'lua vim.env.NVIM = nil; vim.env.MULTIPLEXER = nil',
      }
      vim.g.startuptime_tries = 20
    end,
  },
  {
    src = 'https://github.com/willothy/flatten.nvim',
    setup = function()
      require('flatten').setup({})
    end,
  },
  {
    src = 'https://github.com/kwkarlwang/bufjump.nvim',
    setup = function()
      require('bufjump').setup({})
    end,
  },
  {
    src = 'https://github.com/abecodes/tabout.nvim',
    setup = function()
      require('tabout').setup({})
    end,
  },
  {
    src = 'https://github.com/j-hui/fidget.nvim',
    setup = function()
      require('fidget').setup({
        notification = {
          window = { winblend = 0 },
        },
      })
    end,
  },
  {
    src = 'https://github.com/MeanderingProgrammer/render-markdown.nvim',
    dependencies = { 'mini.icons', 'nvim-treesitter' },
    setup = function()
      require('render-markdown').setup({})
    end,
  },
  {
    src = 'https://github.com/folke/which-key.nvim',
    init = function()
      vim.o.timeout = true
      vim.o.timeoutlen = 300
    end,
    setup = function()
      require('which-key').setup({
        triggers = {
          { '<auto>', mode = 'nxsot' },
          { 's', mode = 'n' },
        },
      })
    end,
  },
  {
    src = 'https://github.com/gbprod/nord.nvim',
    setup = function()
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
      vim.cmd.colorscheme('nord')
    end,
  },
}
