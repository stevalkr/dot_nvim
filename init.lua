-------------
-- setting --
-------------
require('settings')


-------------
-- autocmd --
-------------
require('autocmds')


-------------
-- mapping --
-------------
require('mappings')


-------------
-- plugins --
-------------
local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({
    'git',
    'clone',
    '--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git',
    '--branch=stable', -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

if vim.env.NVIM then
  require('lazy').setup({
    'willothy/flatten.nvim',
    lazy = false,
    opts = {
      window = {
        open = 'tab'
      }
    }
  })
elseif vim.env.MULTIPLEXER then
  require('lazy').setup({
    'stevalkr/multiplexer.nvim',
    lazy = false,
    dev = true,
    opts = {
      default_resize_amount = 5
    }
  }, {
    dev = {
      path = vim.fn.stdpath('config') .. '/dev'
    }
  })
else
  require('lazy').setup({
    spec = {
      { import = 'plugins' }
    },
    rocks = {
      hererocks = true
    },
    dev = {
      path = vim.fn.stdpath('config') .. '/dev'
    }
  })
end
