-------------
-- setting --
-------------
require('settings')


-------------
-- mapping --
-------------
vim.g.mapleader = ','
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

if os.getenv('NVIM') ~= nil then
  require('lazy').setup({
    'willothy/flatten.nvim',
    lazy = false,
    opts = {
      window = {
        open = 'tab'
      },
    },
  })
else
  require('lazy').setup('plugins')
end
