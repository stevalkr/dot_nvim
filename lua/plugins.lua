local M = {}

function M.setup()
  local specs
  if vim.env.NVIM then
    specs = {
      {
        src = 'https://github.com/willothy/flatten.nvim',
        setup = function()
          require('flatten').setup({ window = { open = 'tab' } })
        end,
      },
    }
  elseif vim.env.MULTIPLEXER then
    specs = {
      vim.tbl_extend('force', require('plugins.multiplexer')[1], {
        setup = function()
          require('multiplexer').setup({ default_resize_amount = 5 })
        end,
      }),
    }
  else
    local directory = vim.fs.joinpath(
      vim.fs.dirname(debug.getinfo(1, 'S').source:sub(2)),
      'plugins'
    )
    specs = require('plugin_loader').discover(directory)
  end
  require('plugin_loader').setup(specs)
end

return M
