return {

  {
    'neovim/nvim-lspconfig',
    event = { 'BufReadPre', 'BufNewFile' },
    config = require('plugins.configs.nvim-lspconfig').config
  },

  {
    'L3MON4D3/LuaSnip',
    lazy = true,
    build = 'make install_jsregexp',
    config = function()
      require('luasnip').config.setup({
        region_check_events = 'CursorHold,InsertLeave,InsertEnter',
        delete_check_events = 'TextChanged,InsertEnter',
      })
    end,
  },

  {
    'hrsh7th/nvim-cmp',
    version = false,
    event = { 'InsertEnter', 'CmdlineEnter' },
    dependencies = {
      { 'hrsh7th/cmp-nvim-lsp' },
      { 'hrsh7th/cmp-buffer' },
      { 'hrsh7th/cmp-cmdline' },
      { 'hrsh7th/cmp-path' },
      { 'saadparwaiz1/cmp_luasnip' },
    },
    config = require('plugins.configs.nvim-cmp').config
  },

  {
    'jose-elias-alvarez/null-ls.nvim',
    event = { 'BufReadPre', 'BufNewFile' },
    dependencies = {
      'nvim-lua/plenary.nvim',
    },
    config = require('plugins.configs.null-ls').config
  },

}