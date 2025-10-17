return {

  'nvim-treesitter/nvim-treesitter',
  lazy = false,
  branch = 'main',
  build = function()
    require('nvim-treesitter.install').update()
  end,

  config = function()
    local servers = {
      'bash',
      'c',
      'cmake',
      'comment',
      'cpp',
      'csv',
      'diff',
      'fish',
      'go',
      'json',
      'lua',
      'make',
      'markdown',
      'markdown_inline',
      'meson',
      'nix',
      'python',
      'ron',
      'rust',
      'tmux',
      'toml',
      'vim',
      'vimdoc',
      'yaml',
    }

    require('nvim-treesitter').install(servers)

    for _, server in ipairs(servers) do
      vim.api.nvim_create_autocmd('FileType', {
        pattern = { server },
        callback = function(args)
          local bufnr = args.buf
          local language =
            vim.treesitter.language.get_lang(vim.bo[bufnr].filetype)
          if language and vim.treesitter.language.add(language) then
            vim.treesitter.start()
            vim.bo[bufnr].indentexpr =
              "v:lua.require('nvim-treesitter').indentexpr()"
          end
        end,
      })
    end
  end,
}
