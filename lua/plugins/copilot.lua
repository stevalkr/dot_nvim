return {

  'github/copilot.vim',
  event = { 'BufReadPost' },
  build = ':Copilot setup',

  config = function(_, _opt)
    vim.keymap.set('i', '<C-CR>', 'copilot#Accept("\\<CR>")', {
      expr = true,
      replace_keycodes = false
    })
    vim.g.copilot_no_tab_map = true
  end

}
