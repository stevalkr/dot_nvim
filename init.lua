-------------
-- setting --
-------------
local nvim_data = vim.fn.stdpath('data')
local python_provider = nvim_data .. '/python/bin/python'
local node_root = nvim_data .. '/node'
local node_bin = node_root .. '/bin'
local node_modules_bin = node_root .. '/packages/node_modules/.bin'
local node_path = vim.uv.fs_realpath(node_bin .. '/node')
local node_runtime_bin = node_path and vim.fn.fnamemodify(node_path, ':h')
  or node_bin

vim.g.python3_host_prog = python_provider
vim.g.node_host_prog = node_modules_bin .. '/neovim-node-host'
vim.env.PATH = table.concat(
  { node_bin, node_runtime_bin, node_modules_bin, vim.env.PATH },
  ':'
)

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
require('plugins').setup()
