return {

  'zbirenbaum/copilot.lua',
  event = { 'InsertEnter' },

  opts = {
    suggestion = {
      auto_trigger = true,
      keymap = {
        accept = '<C-CR>',
        accept_word = '<M-l>',
      },
    },
  },
}
