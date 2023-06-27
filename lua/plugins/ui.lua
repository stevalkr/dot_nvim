return {

  {
    'shaunsingh/nord.nvim',
    config = function()
      vim.cmd [[colorscheme nord]]
      vim.cmd [[highlight Normal guibg=NONE ctermbg=NONE]]
      vim.cmd [[highlight NonText guibg=NONE ctermbg=NONE]]
      vim.cmd [[highlight SignColumn guibg=NONE ctermbg=NONE]]
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
