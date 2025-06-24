local utils = require('utils')

return {

  'lionyxml/nvim-0x0',
  config = function()
    local n0x0 = require('nvim-0x0')
    n0x0.setup({ use_default_keymaps = false })

    utils.keymap('n', '<leader>0', function() n0x0.upload_current_file({ append_filename = true }) end,
      'Upload current file')
    utils.keymap('v', '<leader>0', n0x0.upload_selection, 'Upload selection')
  end

}
