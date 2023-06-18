local M = {}

function M.signature_help_handler(_, result, ctx, config)
  config = config or {}
  config.focus_id = ctx.method
  if vim.api.nvim_get_current_buf() ~= ctx.bufnr then
    -- Ignore result since buffer changed. This happens for slow language servers.
    return
  end
  -- When use `autocmd CompleteDone <silent><buffer> lua vim.lsp.buf.signature_help()` to call signatureHelp handler
  -- If the completion item doesn't have signatures It will make noise. Change to use `print` that can use `<silent>` to ignore

  if not (result and result.signatures) then
    if config.silent ~= true then
      print('No signature help available')
    end
    return
  end

  local act_sig = (config.active_signature or 1)
  if act_sig <= #result.signatures then
    result.activeSignature = act_sig - 1
  end

  local client = vim.lsp.get_client_by_id(ctx.client_id)
  local triggers =
      vim.tbl_get(client.server_capabilities, 'signatureHelpProvider', 'triggerCharacters')
  local ft = vim.api.nvim_buf_get_option(ctx.bufnr, 'filetype')
  local lines, hl = vim.lsp.util.convert_signature_help_to_markdown_lines(result, ft, triggers)
  lines = vim.lsp.util.trim_empty_lines(lines)
  if vim.tbl_isempty(lines) then
    if config.silent ~= true then
      print('No signature help available')
    end
    return
  end
  local fbuf, fwin = vim.lsp.util.open_floating_preview(lines, 'markdown', config)
  if hl then
    vim.api.nvim_buf_add_highlight(fbuf, -1, 'LspSignatureActiveParameter', 0, unpack(hl))
  end
  return fbuf, fwin
end

function M.config(_, _opts)
  local lspconfig = require('lspconfig')
  local capabilities = require('cmp_nvim_lsp').default_capabilities()

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
      local kopts = { noremap = true, silent = true }
      vim.keymap.set('n', '<leader>c', '<Cmd>ClangdSwitchSourceHeader<CR>', kopts)
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


  -- Global mappings.
  -- See `:help vim.diagnostic.*` for documentation on any of the below functions
  local kopts = { noremap = true, silent = true }
  vim.keymap.set('n', '<leader>d', vim.diagnostic.open_float, kopts)
  vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, kopts)
  vim.keymap.set('n', ']d', vim.diagnostic.goto_next, kopts)
  -- vim.keymap.set('n', '<space>q', vim.diagnostic.setloclist, kopts)

  -- Use LspAttach autocommand to only map the following keys
  -- after the language server attaches to the current buffer
  vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup('UserLspConfig', {}),
    callback = function(ev)
      -- Enable completion triggered by <c-x><c-o>
      vim.bo[ev.buf].omnifunc = 'v:lua.vim.lsp.omnifunc'

      -- Buffer local mappings.
      -- See `:help vim.lsp.*` for documentation on any of the below functions
      kopts.buffer = ev.buf
      vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, kopts)
      vim.keymap.set('n', 'gd', vim.lsp.buf.definition, kopts)
      vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, kopts)
      vim.keymap.set('n', 'gr', vim.lsp.buf.references, kopts)
      vim.keymap.set('n', 'K', vim.lsp.buf.hover, kopts)
      vim.keymap.set('i', '<C-k><C-k>', vim.lsp.buf.signature_help, kopts)
      -- vim.keymap.set('n', '<space>wa', vim.lsp.buf.add_workspace_folder, kopts)
      -- vim.keymap.set('n', '<space>wr', vim.lsp.buf.remove_workspace_folder, kopts)
      -- vim.keymap.set('n', '<space>wl', function()
      --   print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
      -- end, kopts)
      vim.keymap.set('n', '<leader>D', vim.lsp.buf.type_definition, kopts)
      vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, kopts)
      vim.keymap.set({ 'n', 'v' }, '<leader>ca', vim.lsp.buf.code_action, kopts)
      vim.keymap.set({ 'n', 'v' }, '<leader>f', function()
        vim.lsp.buf.format { async = true }
      end, kopts)

      local telescope = require('telescope.builtin')
      if telescope then
        vim.keymap.set('n', '<leader>d', telescope.diagnostics, kopts)
        vim.keymap.set('n', 'gd', telescope.lsp_definitions, kopts)
        vim.keymap.set('n', 'gi', telescope.lsp_implementations, kopts)
        vim.keymap.set('n', 'gr', telescope.lsp_references, kopts)
        vim.keymap.set('n', '<leader>D', telescope.lsp_type_definitions, kopts)
        vim.keymap.set('n', '<leader>s', telescope.lsp_document_symbols, kopts)
        vim.keymap.set('n', '<leader>S', telescope.lsp_workspace_symbols, kopts)
      end
    end,
  })
end

return M
