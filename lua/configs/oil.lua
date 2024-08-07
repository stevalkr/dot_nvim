local M = {}
local utils = require('utils')

M.config = function(_, _opt)
  require('oil').setup({
    columns = {
      'icon',
      'permissions',
      'size',
      'mtime',
    },
    delete_to_trash = false,
    keymaps = {
      ['g?'] = 'actions.show_help',
      ['yp'] = 'actions.copy_entry_path',
      -- ['sl'] = 'actions.select_vsplit',
      -- ['sj'] = 'actions.select_split',
      -- ['st'] = 'actions.select_tab',
      ['<Esc>'] = 'actions.close',
      ['<C-p>'] = 'actions.preview',
      ['<C-d>'] = 'actions.preview_scroll_down',
      ['<C-u>'] = 'actions.preview_scroll_up',
      ['<C-r>'] = 'actions.refresh',
      ['<CR>'] = 'actions.select',
      ['<BS>'] = 'actions.parent',
      ['E'] = 'actions.open_cwd',
      ['cd'] = 'actions.cd',
      ['tcd'] = 'actions.tcd',
      ['S'] = 'actions.change_sort',
      ['O'] = 'actions.open_external',
      ['H'] = 'actions.toggle_hidden',
      ['T'] = 'actions.toggle_trash',
    },
    use_default_keymaps = false,
    float = {
      padding = 10,
    },
  })
  utils.keymap('n', ';o', require('oil').open, 'Open Oil')
  utils.keymap('n', ';O', require('oil').open_float, 'Open Oil in Float')
end

return M
