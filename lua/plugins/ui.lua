return {

  {
    'shaunsingh/nord.nvim',
    config = function()
      vim.cmd [[colorscheme nord]]

      vim.g.nord_disable_background = true
      require('nord').set()

      local colors = require('nord.colors')
      require('nord.util').highlight('@type.qualifier.cpp',
        { fg = colors.nord6_gui, style = 'italic' }
      )
      require('nord.util').highlight('@lsp.typemod.variable.readonly.cpp',
        { style = 'undercurl' }
      )
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
