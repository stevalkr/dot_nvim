local utils = require('utils')
return {

  'ibhagwan/fzf-lua',
  dependencies = { 'echasnovski/mini.icons' },

  config = function()
    local fzf = require('fzf-lua')
    local actions = fzf.actions
    fzf.setup({
      keymap = {
        builtin = {
          ['<C-d>'] = 'preview-page-down',
          ['<C-u>'] = 'preview-page-up',
        },
      },
      files = {
        actions = {
          ['ctrl-q'] = {
            fn = actions.file_edit_or_qf,
          },
        },
      },
      grep = {
        actions = {
          ['ctrl-q'] = {
            fn = actions.file_edit_or_qf,
          },
        },
      },
    })

    utils.keymap('n', ';;', fzf.resume, 'Resume')
    utils.keymap('n', ';a', fzf.builtin, 'Fzf builtin')
    utils.keymap('n', ';f', fzf.files, 'Find files')
    utils.keymap('n', ';g', fzf.live_grep, 'Live grep')
    utils.keymap('v', ';g', fzf.grep_visual, 'Grep string')
    utils.keymap('n', ';b', fzf.buffers, 'Buffers')

    utils.keymap('n', 'gd', function()
      fzf.lsp_definitions({ jump1 = true })
    end, 'Go to definitions')
    utils.keymap('n', 'gD', function()
      fzf.lsp_declarations({ jump1 = true })
    end, 'Go to declarations')
    utils.keymap('n', 'gi', function()
      fzf.lsp_implementations({ jump1 = true })
    end, 'Go to implementations')
    utils.keymap('n', 'gr', function()
      fzf.lsp_references({ jump1 = true, ignore_current_line = true })
    end, 'Go to references')
    utils.keymap(
      'n',
      '<leader>D',
      fzf.diagnostics_document,
      'Diagnostics document'
    )
    utils.keymap('n', '<leader>s', fzf.lsp_document_symbols, 'Document symbols')
    utils.keymap(
      'n',
      '<leader>S',
      fzf.lsp_workspace_symbols,
      'Workspace symbols'
    )
    utils.keymap(
      { 'n', 'v' },
      '<leader>ca',
      fzf.lsp_code_actions,
      'Code actions'
    )
  end,
}
