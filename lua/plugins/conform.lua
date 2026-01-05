local utils = require('utils')

return {

  'stevearc/conform.nvim',
  config = function()
    local conform = require('conform')
    conform.setup({
      formatters_by_ft = {
        js = { 'prettierd', lsp_format = 'fallback' },
        json = { 'prettierd', lsp_format = 'fallback' },
        lua = { 'stylua', lsp_format = 'fallback' },
        nix = { 'nixfmt', lsp_format = 'fallback' },
        rust = { 'rustfmt', lsp_format = 'fallback' },
        python = { 'black', lsp_format = 'fallback' },
        c = { 'clang-format', lsp_format = 'fallback' },
        cpp = { 'clang-format', lsp_format = 'fallback' },
        fish = { 'fish_indent', lsp_format = 'fallback' },
        cmake = { 'cmake-format', lsp_format = 'fallback' },
        markdown = { 'injected', lsp_format = 'fallback' },
      },
    })

    utils.keymap({ 'n', 'v' }, '<leader>f', function()
      conform.format({ async = true })
    end, 'Format code')
  end,
}
