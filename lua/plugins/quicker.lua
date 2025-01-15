local utils = require('utils')

return {

  'stevearc/quicker.nvim',

  config = function()
    local quicker = require('quicker')

    utils.keymap('n', ';q', function()
      quicker.toggle({ open_cmd_mods = { split = 'botright' } })
    end, 'Toggle quickfix')
    utils.keymap('n', ';l', function()
      quicker.toggle({ loclist = true })
    end, 'Close quickfix')

    quicker.setup({
      keys = {
        { '<', function() quicker.collapse() end,                                                desc = 'Collapse quickfix context', },
        { '>', function() quicker.expand({ before = 2, after = 2, add_to_existing = true }) end, desc = 'Expand quickfix context', },
      }
    })
  end

}
