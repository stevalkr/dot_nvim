local utils = require('utils')
return {

  "ibhagwan/fzf-lua",
  dependencies = { "echasnovski/mini.icons" },

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
      grep = {
        actions = {
          ['ctrl-q'] = {
            fn = actions.file_edit_or_qf, prefix = 'select-all+'
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
    utils.keymap('n', ';q', fzf.quickfix, 'Quickfix')

    utils.keymap('n', 'gd', fzf.lsp_definitions, 'Go to definitions')
    utils.keymap('n', 'gD', fzf.lsp_declarations, 'Go to declarations')
    utils.keymap('n', 'gi', fzf.lsp_implementations, 'Go to implementations')
    utils.keymap('n', 'gr', fzf.lsp_references, 'Go to references')
    utils.keymap('n', '<leader>D', fzf.diagnostics_document, 'Diagnostics document')
    utils.keymap('n', '<leader>s', fzf.lsp_document_symbols, 'Document symbols')
    utils.keymap('n', '<leader>S', fzf.lsp_workspace_symbols, 'Workspace symbols')
    utils.keymap('n', '<leader>ca', fzf.lsp_code_actions, 'Code actions')
  end

}
