local utils = require('utils')
return {
  'neovim/nvim-lspconfig',
  event = { 'BufReadPre', 'BufNewFile' },

  config = function()
    local lspconfig = require('lspconfig')
    local capabilities = require('cmp_nvim_lsp').default_capabilities()

    vim.lsp.inlay_hint.enable()

    lspconfig['nixd'].setup({})
    lspconfig['zls'].setup({ capabilities = capabilities })
    lspconfig['gopls'].setup({ capabilities = capabilities })
    lspconfig['svelte'].setup({ capabilities = capabilities })
    lspconfig['pyright'].setup({ capabilities = capabilities })
    lspconfig['tsserver'].setup({ capabilities = capabilities })
    lspconfig['rust_analyzer'].setup({ capabilities = capabilities })
    lspconfig['elixirls'].setup({ capabilities = capabilities, cmd = { 'elixir-ls' } })

    lspconfig['clangd'].setup({
      capabilities = capabilities,
      cmd = {
        'clangd',
        '--offset-encoding=utf-16',
        '--background-index',
        '--pch-storage=memory',
        '--clang-tidy',
        '--all-scopes-completion',
        '--cross-file-rename',
        '--completion-style=detailed',
      },
      on_attach = function(_client, _bufnr)
        utils.keymap('n', '<leader>cc', '<Cmd>ClangdSwitchSourceHeader<CR>', 'Switch to source/header')
        vim.bo.errorformat = '' ..
            '%-GIn file included from %f:%l:%c:,' ..
            '%-GIn file included from %f:%l:,' ..
            '%-GIn file included from %f:%l:%c,' ..
            '%-GIn file included from %f:%l,' ..
            '%A%f:%l:%c: %m,' ..
            '%Z%.%#^%.%#,' ..
            '%C%m,'
      end
    })

    lspconfig['lua_ls'].setup({
      capabilities = capabilities,
      settings = {
        Lua = {
          runtime = {
            version = 'LuaJIT',
          },
          diagnostics = {
            globals = { 'vim' },
          },
          workspace = {
            library = vim.api.nvim_get_runtime_file("", true),
            checkThirdParty = false,
          },
          telemetry = {
            enable = false,
          },
        },
      },
    })


    -- Global mappings.
    -- See `:help vim.diagnostic.*` for documentation on any of the below functions
    utils.keymap('n', '<leader>d', vim.diagnostic.open_float, 'Open diagnostic')
    utils.keymap('n', '<leader>q', vim.diagnostic.setloclist, 'Set diagnostic loclist')
    utils.keymap('n', '<leader>Q', vim.diagnostic.setqflist, 'Set diagnostic quickfix')

    -- Use LspAttach autocommand to only map the following keys
    -- after the language server attaches to the current buffer
    vim.api.nvim_create_autocmd('LspAttach', {
      group = vim.api.nvim_create_augroup('UserLspConfig', {}),
      callback = function(ev)
        -- Enable completion triggered by <c-x><c-o>
        vim.bo[ev.buf].omnifunc = 'v:lua.vim.lsp.omnifunc'

        -- Buffer local mappings.
        -- See `:help vim.lsp.*` for documentation on any of the below functions
        local kopts = { buffer = ev.buf }
        utils.keymap('n', 'gd', vim.lsp.buf.definition, 'Go to definition', kopts)
        utils.keymap('n', 'gD', vim.lsp.buf.declaration, 'Go to declaration', kopts)
        utils.keymap('n', 'gi', vim.lsp.buf.implementation, 'Go to implementation', kopts)
        utils.keymap('n', 'gr', vim.lsp.buf.references, 'Go to references', kopts)
        utils.keymap('n', 'K', vim.lsp.buf.hover, 'Hover', kopts)
        utils.keymap('i', '<C-k>', vim.lsp.buf.signature_help, 'Signature help', kopts)
        -- utils.keymap('n', '<leader>D', vim.lsp.buf.type_definition, 'Go to type definition', kopts)

        -- utils.keymap('n', '<leader>wa', vim.lsp.buf.add_workspace_folder, 'Add workspace', kopts)
        -- utils.keymap('n', '<leader>wr', vim.lsp.buf.remove_workspace_folder, 'Remove workspace', kopts)
        -- utils.keymap('n', '<leader>wl', function()
        --   print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
        -- end, 'List workspace', kopts)

        utils.keymap('n', '<leader>rn', vim.lsp.buf.rename, 'Rename', kopts)
        utils.keymap({ 'n', 'v' }, '<leader>ca', vim.lsp.buf.code_action, 'Code action', kopts)
        utils.keymap({ 'n', 'v' }, '<leader>f', function() vim.lsp.buf.format { async = true } end, 'Format', kopts)
      end,
    })
  end

}
