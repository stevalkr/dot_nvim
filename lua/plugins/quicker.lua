return {

  'stevearc/quicker.nvim',

  config = function()
    local quicker = require('quicker')
    quicker.setup({
      keys = {
        { '<', function() quicker.collapse() end,                                                desc = 'Collapse quickfix context', },
        { '>', function() quicker.expand({ before = 2, after = 2, add_to_existing = true }) end, desc = 'Expand quickfix context', },
      },
    })
  end

}
