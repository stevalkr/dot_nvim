local utils = require('utils')
return {

  'zbirenbaum/copilot.lua',
  event = { 'InsertEnter' },

  opts = {
    suggestion = {
      auto_trigger = true,
      keymap = {
        accept = '<C-CR>',
        accept_word = '<C-l>'
      }
    }
  }

}
