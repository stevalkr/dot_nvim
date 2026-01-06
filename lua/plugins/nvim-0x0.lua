local utils = require('utils')

return {

  'stevalkr/nvim-0x0',

  config = function()
    local n0x0 = require('nvim-0x0')
    n0x0.setup({
      base_url = 'https://0x0.ethero.xyz',
      use_default_keymaps = false,
    })

    utils.keymap(
      'n',
      '<leader>0',
      n0x0.upload_current_file,
      'Upload current file'
    )
    utils.keymap('v', '<leader>0', n0x0.upload_selection, 'Upload selection')
  end,
}
