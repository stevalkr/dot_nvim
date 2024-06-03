return {

  {
    'gbprod/nord.nvim',
    config = function()
      require('nord').setup({
        transparent = true,         -- Enable this to disable setting the background color
        terminal_colors = true,     -- Configure the colors used when opening a `:terminal` in Neovim
        diff = { mode = 'bg' },     -- enables/disables colorful backgrounds when used in diff mode. values : [bg|fg]
        borders = true,             -- Enable the border between vertically split windows visible
        errors = { mode = 'bg' },   -- Display mode for errors and diagnostics
        -- values : [bg|fg|none]
        search = { theme = 'vim' }, -- theme for highlighting search results
        -- values : [vim|vscode]
        styles = {
          -- Style to be applied to different syntax groups
          -- Value is any valid attr-list value for `:help nvim_set_hl`
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
      -- your configuration comes here
      -- or leave it empty to use the default settings
      -- refer to the configuration section below
    }
  }

}
