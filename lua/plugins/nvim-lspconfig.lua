local utils = require('utils')
return {

  'neovim/nvim-lspconfig',
  event = { 'BufReadPre', 'BufNewFile' },

  config = function()
    local capabilities = vim.lsp.protocol.make_client_capabilities()
    if utils.has_plugin('blink.cmp') then
      capabilities = require('blink.cmp').get_lsp_capabilities()
    end

    vim.lsp.inlay_hint.enable()
    vim.diagnostic.config({
      virtual_text = { severity = { max = vim.diagnostic.severity.WARN } },
      virtual_lines = { severity = vim.diagnostic.severity.ERROR },
      update_in_insert = false,
      severity_sort = true,
    })
    vim.lsp.config('*', {
      capabilities = capabilities,
    })

    vim.lsp.enable('zls')
    vim.lsp.enable('nixd')
    vim.lsp.enable('gopls')
    vim.lsp.enable('clangd')
    vim.lsp.enable('lua_ls')
    vim.lsp.enable('svelte')
    vim.lsp.enable('pyright')
    vim.lsp.enable('elixirls')
    vim.lsp.enable('rust_analyzer')

    vim.lsp.config('clangd', {
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
        utils.keymap(
          'n',
          '<leader>cc',
          '<Cmd>ClangdSwitchSourceHeader<CR>',
          'Switch to source/header'
        )
        vim.bo.errorformat = ''
          .. '%-GIn file included from %f:%l:%c:,'
          .. '%-GIn file included from %f:%l:,'
          .. '%-GIn file included from %f:%l:%c,'
          .. '%-GIn file included from %f:%l,'
          .. '%A%f:%l:%c: %m,'
          .. '%Z%.%#^%.%#,'
          .. '%C%m,'
      end,
    })

    vim.lsp.config('rust_analyzer', {
      settings = {
        ['rust-analyzer'] = {
          check = { command = 'clippy' },
        },
      },
    })

    vim.lsp.config('lua_ls', {
      on_init = function(client)
        local path = client.workspace_folders
            and client.workspace_folders[1].name
          or '.'
        if
          vim.uv.fs_stat(path .. '/.luarc.json')
          or vim.uv.fs_stat(path .. '/.luarc.jsonc')
        then
          return
        end

        client.config.settings.Lua =
          vim.tbl_deep_extend('force', client.config.settings.Lua, {
            runtime = {
              version = 'LuaJIT',
            },
            workspace = {
              checkThirdParty = false,
              ignoreDir = {
                '.git',
                '.pixi',
                '.cache',
              },
              library = {
                vim.env.VIMRUNTIME,
                '${3rd}/luv/library',
                '${3rd}/busted/library',
              },
            },
          })
      end,
      settings = {
        Lua = {},
      },
    })

    vim.lsp.config('elixirls', {
      cmd = { 'elixir-ls' },
    })

    utils.keymap('n', '<leader>d', vim.diagnostic.open_float, 'Open diagnostic')
    utils.keymap(
      'n',
      '<leader>q',
      vim.diagnostic.setloclist,
      'Set diagnostic loclist'
    )
    utils.keymap(
      'n',
      '<leader>Q',
      vim.diagnostic.setqflist,
      'Set diagnostic quickfix'
    )

    vim.api.nvim_create_autocmd('LspAttach', {
      group = vim.api.nvim_create_augroup('UserLspConfig', {}),
      callback = function(ev)
        vim.bo[ev.buf].omnifunc = 'v:lua.vim.lsp.omnifunc'

        local kopts = { buffer = ev.buf }
        utils.keymap('n', 'K', vim.lsp.buf.hover, 'Hover', kopts)
        utils.keymap(
          'i',
          '<C-k>',
          vim.lsp.buf.signature_help,
          'Signature help',
          kopts
        )

        utils.keymap('n', '<leader>rn', vim.lsp.buf.rename, 'Rename', kopts)

        -- utils.keymap('n', '<leader>D', vim.lsp.buf.type_definition, 'Go to type definition', kopts)
        -- utils.keymap('n', '<leader>wa', vim.lsp.buf.add_workspace_folder, 'Add workspace', kopts)
        -- utils.keymap('n', '<leader>wr', vim.lsp.buf.remove_workspace_folder, 'Remove workspace', kopts)
        -- utils.keymap('n', '<leader>wl', function()
        --   print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
        -- end, 'List workspace', kopts)

        if not utils.has_plugin('conform') then
          utils.keymap({ 'n', 'v' }, '<leader>f', function()
            vim.lsp.buf.format({ async = true })
          end, 'Format', kopts)
        end

        if not utils.has_plugin('fzf-lua') then
          utils.keymap(
            'n',
            'gd',
            vim.lsp.buf.definition,
            'Go to definition',
            kopts
          )
          utils.keymap(
            'n',
            'gD',
            vim.lsp.buf.declaration,
            'Go to declaration',
            kopts
          )
          utils.keymap(
            'n',
            'gi',
            vim.lsp.buf.implementation,
            'Go to implementation',
            kopts
          )
          utils.keymap(
            'n',
            'gr',
            vim.lsp.buf.references,
            'Go to references',
            kopts
          )
          utils.keymap(
            { 'n', 'v' },
            '<leader>ca',
            vim.lsp.buf.code_action,
            'Code action',
            kopts
          )
        end

        if
          not utils.has_plugin('blink.cmp') and vim.fn.has('nvim-0.11') == 1
        then
          vim.opt.pumheight = 10
          vim.opt.completeopt = 'menu,menuone,popup,fuzzy'
          -- https://github.com/neovim/neovim/issues/29225
          vim.lsp.completion.enable(
            true,
            ev.data.client_id,
            ev.buf,
            { autotrigger = false }
          )
        end

        local client = vim.lsp.get_client_by_id(ev.data.client_id)
        if client and client:supports_method('textDocument/foldingRange') then
          local win = vim.api.nvim_get_current_win()
          vim.wo[win][0].foldmethod = 'expr'
          vim.wo[win][0].foldexpr = 'v:lua.vim.lsp.foldexpr()'
        end
      end,
    })
  end,
}
