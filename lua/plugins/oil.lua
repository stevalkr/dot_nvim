local utils = require('utils')
return {

  'stevearc/oil.nvim',
  dependencies = { 'echasnovski/mini.icons' },

  dir = '/Users/walker/Downloads/oil.nvim',
  dev = true,

  config = function()
    local oil = require('oil')
    oil.setup({
      columns = {
        -- 'permissions',
        'mtime',
        'size',
        'icon',
      },
      lsp_file_methods = {
        autosave_changes = 'unmodified',
      },
      keymaps = {
        ['g?']         = 'actions.show_help',
        ['yp']         = 'actions.copy_entry_path',
        ['<CR>']       = 'actions.select',
        ['J']          = 'actions.select_split',
        ['L']          = 'actions.select_vsplit',
        ['T']          = 'actions.select_tab',
        ['<C-p>']      = 'actions.preview',
        ['<C-d>']      = 'actions.preview_scroll_down',
        ['<C-u>']      = 'actions.preview_scroll_up',
        ['<C-r>']      = 'actions.refresh',
        ['<BS>']       = 'actions.parent',
        ['<C-e>']      = 'actions.open_cwd',
        ['<Esc><Esc>'] = 'actions.close',
        ['cd']         = 'actions.cd',
        ['tcd']        = 'actions.tcd',
        ['E']          = 'actions.open_cwd',
        ['S']          = 'actions.change_sort',
        ['H']          = 'actions.toggle_hidden',
        ['gy']         = 'actions.copy_to_system_clipboard',
        ['gp']         = 'actions.paste_from_system_clipboard',
        -- ['<C-t>']      = 'actions.toggle_trash',
        -- ['<C-o>']      = 'actions.open_external',
      },
      use_default_keymaps = false,
    })
    utils.keymap('n', ';e', oil.open, 'Open Oil')
    utils.keymap('n', ';E', oil.open_float, 'Open Oil in Float')
  end

}
