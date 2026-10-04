-------------
-- setting --
-------------
local nvim_data = vim.fn.stdpath('data')
local python_provider = nvim_data .. '/python/bin/python'
local node_root = nvim_data .. '/node'
local node_bin = node_root .. '/bin'
local node_modules_bin = node_root .. '/packages/node_modules/.bin'
local node_path = vim.uv.fs_realpath(node_bin .. '/node')
local node_runtime_bin = node_path and vim.fn.fnamemodify(node_path, ':h') or node_bin

vim.g.python3_host_prog = python_provider
vim.g.node_host_prog = node_modules_bin .. '/neovim-node-host'
vim.env.PATH = table.concat({ node_bin, node_runtime_bin, node_modules_bin, vim.env.PATH }, ':')

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
        open = 'tab',
      },
    },
  })
elseif vim.env.MULTIPLEXER then
  require('lazy').setup({
    'stevalkr/multiplexer.nvim',
    lazy = false,
    dev = true,
    opts = {
      default_resize_amount = 5,
    },
  }, {
    dev = {
      path = vim.fn.stdpath('config') .. '/dev',
    },
  })
else
  require('lazy').setup({
    spec = {
      { import = 'plugins' },
    },
    dev = {
      path = vim.fn.stdpath('config') .. '/dev',
    },
  })
end
