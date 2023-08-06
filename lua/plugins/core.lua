return {

  {
    'folke/lazy.nvim',
    version = '*'
  },

  {
    'nvim-telescope/telescope.nvim',
    version = false,
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-tree/nvim-web-devicons',
      'BurntSushi/ripgrep',
      'nvim-telescope/telescope-file-browser.nvim',
      { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' }
    },
    config = require('configs.telescope').config
  },

  {
    'nvim-treesitter/nvim-treesitter',
    lazy = false,
    build = function()
      require('nvim-treesitter.install').update({ with_sync = true })
    end,
    config = require('configs.nvim-treesitter').config
  },

}
