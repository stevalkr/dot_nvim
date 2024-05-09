return {

  {
    'neovim/nvim-lspconfig',
    event = { 'BufReadPre', 'BufNewFile' },
    config = require('configs.nvim-lspconfig').config
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
    config = require('configs.nvim-cmp').config
  },

  {
    'nvimtools/none-ls.nvim',
    event = { 'BufReadPre', 'BufNewFile' },
    dependencies = {
      'nvim-lua/plenary.nvim',
    },
    config = require('configs.null-ls').config
  },

  {
    'github/copilot.vim',
    event = { 'BufReadPost' },
    build = '<Cmd>Copilot setup',
    config = function(_, _opt)
      vim.keymap.set('i', '<C-CR>', 'copilot#Accept("\\<CR>")', {
        expr = true,
        replace_keycodes = false
      })
      vim.g.copilot_no_tab_map = true
    end
  }

}
