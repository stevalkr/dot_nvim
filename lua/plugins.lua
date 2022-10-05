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
local conf = require('plug_configs')

return require('packer').startup({ function(use)
  use 'wbthomason/packer.nvim'

  -- plugins
  use({'ryanoasis/vim-devicons'})
  use({
    'SmiteshP/nvim-navic',
    requires = 'neovim/nvim-lspconfig'
  })
  use({
    'Pocco81/auto-save.nvim',
    config = conf.auto_save
  })
  use({
    'lewis6991/gitsigns.nvim',
    config = conf.gitsigns,
    event = {'BufReadPost', 'BufNewFile'},
  })
  use({
    'rcarriga/nvim-notify',
    config = conf.notify
  })
  use({'nvim-lua/popup.nvim'})
  use({'nvim-lua/plenary.nvim'})
  use({
    'rainbowhxch/accelerated-jk.nvim',
    config = conf.accelerated_jk,
    event = 'BufWinEnter'
  })
  use({
    'nathom/filetype.nvim',
    config = conf.filetype
  })
  use({
    'RRethy/vim-illuminate',
    event = 'BufReadPost',
  })
  use({
    'terrortylor/nvim-comment',
    config = conf.comment,
    event = 'BufReadPost',
  })
  use({
    'karb94/neoscroll.nvim',
    config = conf.neoscroll,
    event = 'BufReadPost',
  })
  use({
    'max397574/better-escape.nvim',
    config = conf.better_escape,
    event = 'BufReadPost',
  })
  use({
    'edluffy/specs.nvim',
    config = conf.specs,
    event = 'CursorMoved',
  })
  use({
    'luukvbaal/stabilize.nvim',
    config = conf.stabilize
  })
  use({
    'nvim-treesitter/nvim-treesitter',
    config = conf.treesitter,
    run = ':TSUpdate',
    event = 'BufReadPost',
  })
  use({
    'p00f/nvim-ts-rainbow',
    after = 'nvim-treesitter',
  })
  use({
    'windwp/nvim-ts-autotag',
    after = 'nvim-treesitter',
  })
  use({
    'windwp/nvim-autopairs',
    config = conf.autopairs,
    event = 'InsertEnter',
  })
  use({
    'abecodes/tabout.nvim',
    config = conf.tabout,
    event = 'InsertEnter',
    wants = 'nvim-treesitter',
    after = 'nvim-cmp'
  })
  use({
    'lewis6991/impatient.nvim',
    config = conf.impatient,
  })


  -- search
  use({
    'nvim-telescope/telescope.nvim',
    config = conf.telescope,
    branch = '0.1.x',
    requires = {
      { 'nvim-lua/popup.nvim' },
      { 'nvim-lua/plenary.nvim' },
      { 'nvim-telescope/telescope-fzf-native.nvim', run = 'make' },
      { 'nvim-telescope/telescope-ui-select.nvim' }
      -- { 'nvim-telescope/telescope-frecency.nvim' },
      -- { 'nvim-telescope/telescope-z.nvim' },
    }
  })


  -- debug
  use({
    'akinsho/toggleterm.nvim',
    tag = '*',
    config = conf.toggleterm,
    event = 'UIEnter',
  })
  use({
    'michaelb/sniprun',
    config = conf.sniprun,
    ft = {'cpp', 'c', 'python', 'lua', 'go', 'cmake'}
  })
  use({
    'mfussenegger/nvim-dap',
    config = conf.dap,
    ft = {'cpp', 'go'},
  })
  use({
    'rcarriga/nvim-dap-ui',
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
    'WhoIsSethDaniel/mason-tool-installer.nvim',
    config = conf.mason_install
  })
  use({
    'ray-x/lsp_signature.nvim',
    after = 'nvim-lspconfig',
    config = conf.lsp_signature
  })
  use({
    'L3MON4D3/LuaSnip',
    config = conf.luasnip,
    requires = 'rafamadriz/friendly-snippets',
  })
  use({
    'hrsh7th/nvim-cmp',
    config = conf.cmp,
    event = 'InsertEnter',
    requires = {
      { 'saadparwaiz1/cmp_luasnip', after = 'LuaSnip' },
      { 'lukas-reineke/cmp-under-comparator' },
      { 'hrsh7th/cmp-nvim-lsp', after = 'cmp_luasnip' },
      { 'hrsh7th/cmp-nvim-lua', after = 'cmp-nvim-lsp' },
      { 'hrsh7th/cmp-buffer', after = 'cmp-nvim-lua' },
      { 'hrsh7th/cmp-path', after = 'cmp-buffer' },
      { 'f3fora/cmp-spell', after = 'cmp-path' },
      { 'hrsh7th/cmp-cmdline', after = 'cmp-spell' },
    },
  })


  -- languages
  use({
    'github/copilot.vim',
    config = conf.copilot,
    ft = {'cpp', 'c', 'python', 'lua', 'go', 'cmake'}
  })
  use({
    'fatih/vim-go',
    run = ':GoUpdateBinaries',
    config = conf.vim_go,
    ft = {'go'}
  })
  use({
    'buoto/gotests-vim',
    ft = {'go'}
  })


  -- UI
  use({
    'shaunsingh/nord.nvim',
    config = conf.theme
  })
  use({
    'goolord/alpha-nvim',
    config = conf.alpha,
    event = 'BufWinEnter',
  })
  use({
    'glepnir/galaxyline.nvim',
    branch = 'main',
    config = conf.galaxyline,
    requires = { 'kyazdani42/nvim-web-devicons', opt = true },
    event = 'BufReadPost',
  })
  use({
    'akinsho/bufferline.nvim',
    tag = 'v2.*',
    config = conf.bufferline,
    requires = { 'kyazdani42/nvim-web-devicons', opt = true },
    event = 'BufReadPost',
  })
  use({
    'kyazdani42/nvim-tree.lua',
    config = conf.nvim_tree,
    requires = { 'kyazdani42/nvim-web-devicons', opt = true },
    tag = 'nightly'
  })
  use({
    'liuchengxu/vista.vim',
    config = conf.vista
  })
  use({
    'j-hui/fidget.nvim',
    config = conf.fidget,
    event = 'BufReadPost',
  })
  use({
    'lukas-reineke/indent-blankline.nvim',
    config = conf.indent_blankline,
    after = 'nvim-treesitter',
  })

  if packer_bootstrap then
    require('packer').sync()
  end
end,
  config = {
    git = {
      clone_timeout = 60,
      default_url_format = 'git@github.com:%s'
    },
    display = {
      open_fn = function()
        return require('packer.util').float({ border = 'single' })
      end,
    }
  } })
