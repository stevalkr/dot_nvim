local utils = require('utils')

local function setup()
  local quicker = require('quicker')

  quicker.setup({
    keys = {
      {
        '<',
        function()
          quicker.collapse()
        end,
        desc = 'Collapse quickfix context',
      },
      {
        '>',
        function()
          quicker.expand({ before = 2, after = 2, add_to_existing = true })
        end,
        desc = 'Expand quickfix context',
      },
    },
  })

  utils.keymap('n', ';q', function()
    quicker.toggle({ open_cmd_mods = { split = 'botright' } })
  end, 'Toggle quickfix')
  utils.keymap('n', ';l', function()
    quicker.toggle({ loclist = true })
  end, 'Close quickfix')
end

return {
  {
    src = 'https://github.com/stevearc/quicker.nvim',
    setup = setup,
  },
}
