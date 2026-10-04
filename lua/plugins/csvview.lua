local function setup()
  require('csvview').setup({})
end

return {
  {
    src = 'https://github.com/hat0uma/csvview.nvim',
    setup = setup,
  },
}
