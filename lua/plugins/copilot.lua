local function setup()
  require('copilot').setup({
    suggestion = {
      auto_trigger = true,
      keymap = {
        accept = '<C-CR>',
        accept_word = '<M-l>',
      },
    },
  })
end

return {
  {
    src = 'https://github.com/zbirenbaum/copilot.lua',
    setup = setup,
  },
}
