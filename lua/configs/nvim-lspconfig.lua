local M = {}
local utils = require('utils')

function M.config(_, _opts)
  local lspconfig = require('lspconfig')
  local capabilities = require('cmp_nvim_lsp').default_capabilities()

  vim.lsp.inlay_hint.enable()

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
    end
  })

  lspconfig['pyright'].setup({
    capabilities = capabilities,
  })

  lspconfig['gopls'].setup({
    capabilities = capabilities,
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

  lspconfig['tsserver'].setup({
    capabilities = capabilities,
  })

  lspconfig['svelte'].setup({
    capabilities = capabilities,
  })

  lspconfig['elixirls'].setup({
    cmd = { 'elixir-ls' },
    capabilities = capabilities,
  })

  lspconfig['tailwindcss'].setup({
    capabilities = capabilities,
    init_options = {
      userLanguages = {
        elixir = "html-eex",
        eelixir = "html-eex",
        heex = "html-eex",
      },
    },
    settings = {
      tailwindCSS = {
        experimental = {
          classRegex = {
            'class[:]\\s*"([^"]*)"',
          },
        },
      },
    },
  })

  lspconfig['rust_analyzer'].setup({
    capabilities = capabilities,
    settings = {
      ['rust-analyzer'] = {
        diagnostics = {
          enable = false,
        }
      }
    },
  })

  lspconfig['zls'].setup({
    capabilities = capabilities,
  })

  lspconfig['ltex'].setup({
    capabilities = capabilities,
    settings = {
      ltex = {
        language = "en-GB",
      },
    },
  })

  lspconfig['nixd'].setup({})

  -- Global mappings.
  -- See `:help vim.diagnostic.*` for documentation on any of the below functions
  utils.keymap('n', '<leader>d', vim.diagnostic.open_float, 'Open diagnostic')
  -- utils.keymap('n', '[d', vim.diagnostic.goto_prev, 'Previous diagnostic')
  -- utils.keymap('n', ']d', vim.diagnostic.goto_next, 'Next diagnostic')
  -- utils.keymap('n', '<space>q', vim.diagnostic.setloclist)

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
      utils.keymap('n', 'gD',
        vim.lsp.buf.declaration, 'Go to declaration',
        kopts
      )
      utils.keymap('n', 'gd',
        vim.lsp.buf.definition, 'Go to definition',
        kopts
      )
      utils.keymap('n', 'gi',
        vim.lsp.buf.implementation, 'Go to implementation',
        kopts
      )
      utils.keymap('n', 'gr',
        vim.lsp.buf.references, 'Go to references',
        kopts
      )
      utils.keymap('n', 'K',
        vim.lsp.buf.hover, 'Hover',
        kopts
      )
      utils.keymap('i', '<C-k>',
        vim.lsp.buf.signature_help, 'Signature help',
        kopts
      )
      -- utils.keymap('n', '<space>wa', vim.lsp.buf.add_workspace_folder, kopts)
      -- utils.keymap('n', '<space>wr', vim.lsp.buf.remove_workspace_folder, kopts)
      -- utils.keymap('n', '<space>wl', function()
      --   print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
      -- end, kopts)
      utils.keymap('n', '<leader>D',
        vim.lsp.buf.type_definition, 'Go to type definition',
        kopts
      )
      utils.keymap('n', '<leader>rn',
        vim.lsp.buf.rename, 'Rename',
        kopts
      )
      utils.keymap({ 'n', 'v' }, '<leader>ca',
        vim.lsp.buf.code_action, 'Code action',
        kopts
      )
      utils.keymap({ 'n', 'v' }, '<leader>f',
        function()
          vim.lsp.buf.format { async = true }
        end, 'Format',
        kopts
      )

      local telescope = require('telescope.builtin')
      if telescope then
        -- utils.keymap('n', '<leader>d',
        --   telescope.diagnostics, 'Open diagnostic',
        --   kopts
        -- )
        utils.keymap('n', 'gd',
          telescope.lsp_definitions, 'Go to definition',
          kopts
        )
        utils.keymap('n', 'gi',
          telescope.lsp_implementations, 'Go to implementation',
          kopts
        )
        utils.keymap('n', 'gr',
          telescope.lsp_references, 'Go to references',
          kopts
        )
        utils.keymap('n', '<leader>D',
          telescope.lsp_type_definitions, 'Go to type definition',
          kopts
        )
        utils.keymap('n', '<leader>s',
          telescope.lsp_document_symbols, 'Document symbols',
          kopts
        )
        utils.keymap('n', '<leader>S',
          telescope.lsp_workspace_symbols, 'Workspace symbols',
          kopts
        )
      end
    end,
  })
end

return M
