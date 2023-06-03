local ensure_packer = function()
  local fn = vim.fn
  local install_path = fn.stdpath('data') .. '/site/pack/packer/start/packer.nvim'
  if fn.empty(fn.glob(install_path)) > 0 then
    fn.system({ 'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path })
    vim.cmd [[packadd packer.nvim]]
    return true
  end
  return false
end

local packer_bootstrap = ensure_packer()
local conf = require('configs')

return require('packer').startup({ function(use)
  use 'wbthomason/packer.nvim'

  -- plugins
  -- use({ 'ryanoasis/vim-devicons' })
  -- use({
  --   'SmiteshP/nvim-navic',
  --   requires = 'neovim/nvim-lspconfig'
  -- })
  use({
    'nathom/filetype.nvim', -- startup speedup
    config = conf.filetype
  })
  use({
    'lewis6991/impatient.nvim', -- startup speedup
    config = conf.impatient,
  })
  use({
    'Pocco81/auto-save.nvim', -- auto save
    config = conf.auto_save
  })
  use({
    'windwp/nvim-autopairs', -- auto pair
    config = conf.autopairs,
    event = 'InsertEnter',
  })
  use({
    'lewis6991/gitsigns.nvim', -- git signs
    config = conf.gitsigns,
    event = { 'BufReadPost', 'BufNewFile' },
  })
  -- use({
  --   'rcarriga/nvim-notify',
  --   config = conf.notify
  -- })
  -- use({ 'nvim-lua/popup.nvim' })
  -- use({ 'nvim-lua/plenary.nvim' })
  use({
    'RRethy/vim-illuminate', -- highlight current word
    event = 'BufReadPost',
  })
  use({
    'numToStr/Comment.nvim', -- comment
    config = conf.comment,
    event = 'BufReadPost',
  })
  use({
    'karb94/neoscroll.nvim', -- smooth scroll
    config = conf.neoscroll,
    event = 'BufReadPost',
  })
  use({
    'max397574/better-escape.nvim', -- jj escape
    config = conf.better_escape,
    event = 'BufReadPost',
  })


  -- search
  use({
    'nvim-telescope/telescope.nvim',
    config = conf.telescope,
    branch = '0.1.x',
    requires = {
      { 'nvim-lua/popup.nvim' },
      { 'nvim-lua/plenary.nvim' },
      { 'nvim-tree/nvim-web-devicons' },
      { 'nvim-telescope/telescope-ui-select.nvim' },
      { 'nvim-telescope/telescope-fzf-native.nvim', run = 'make' },
    }
  })


  -- debug
  use({
    'akinsho/toggleterm.nvim', -- terminal
    tag = '*',
    config = conf.toggleterm,
    event = 'UIEnter',
  })
  use({
    'mfussenegger/nvim-dap', -- dap
    config = conf.dap,
    ft = { 'cpp', 'go' },
  })
  use({
    'rcarriga/nvim-dap-ui', -- dap ui
    config = conf.dap_ui,
    after = 'nvim-dap',
  })


  -- lsp
  use({
    'neovim/nvim-lspconfig',
    config = conf.lspconfig,
    event = 'BufReadPre',
  })
  use({
    'williamboman/mason.nvim',
    config = conf.mason
  })
  use({
    'williamboman/mason-lspconfig.nvim',
    config = conf.mason_lspconfig
  })
  use({
    'ray-x/lsp_signature.nvim', -- float box over function
    after = 'nvim-lspconfig',
    config = conf.lsp_signature
  })
  use({
    'L3MON4D3/LuaSnip',
    config = conf.luasnip,
    requires = 'rafamadriz/friendly-snippets',
  })
  use({
    'hrsh7th/nvim-cmp', -- completion
    config = conf.cmp,
    -- event = 'InsertEnter',
    requires = {
      { 'saadparwaiz1/cmp_luasnip', after = 'LuaSnip' },
      { 'hrsh7th/cmp-nvim-lsp', after = 'cmp_luasnip' },
      { 'hrsh7th/cmp-nvim-lua', after = 'cmp-nvim-lsp' },
      { 'hrsh7th/cmp-buffer', after = 'cmp-nvim-lua' },
      { 'hrsh7th/cmp-path', after = 'cmp-buffer' },
      { 'hrsh7th/cmp-cmdline', after = 'cmp-path' },
    },
  })


  -- languages
  use({
    'github/copilot.vim', -- copilot
    config = conf.copilot,
    ft = { 'cpp', 'c', 'python', 'lua', 'go', 'cmake' }
  })
  -- use({
  --   'fatih/vim-go',
  --   run = ':GoUpdateBinaries',
  --   config = conf.vim_go,
  --   ft = { 'go' }
  -- })
  -- use({
  --   'buoto/gotests-vim',
  --   ft = { 'go' }
  -- })
  -- use({
  --   'rust-lang/rust.vim',
  --   config = conf.rust,
  --   ft = { 'rust' }
  -- })


  -- UI
  use({
    'arcticicestudio/nord-vim', -- nord theme
    config = conf.theme
  })
  use({
    'glepnir/galaxyline.nvim', -- bottom line
    branch = 'main',
    config = conf.galaxyline,
    requires = { 'kyazdani42/nvim-web-devicons', opt = true },
    event = 'BufReadPost',
  })
  use({
    'akinsho/bufferline.nvim', -- top line
    tag = 'v2.*',
    config = conf.bufferline,
    requires = { 'kyazdani42/nvim-web-devicons', opt = true },
    event = 'BufReadPost',
  })
  use({
    'kyazdani42/nvim-tree.lua', -- left pane
    config = conf.nvim_tree,
    requires = { 'kyazdani42/nvim-web-devicons', opt = true },
    tag = 'nightly'
  })
  use({
    'liuchengxu/vista.vim', -- right pane
    config = conf.vista
  })

  if packer_bootstrap then
    require('packer').sync()
  end
end,
  config = {
    git = {
      clone_timeout = 10,
      default_url_format = 'git@github.com:%s'
    },
    display = {
      open_fn = function()
        return require('packer.util').float({ border = 'single' })
      end,
    }
  } })
