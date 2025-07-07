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
        callback = function()
          vim.treesitter.start()
        end,
      })
    end
  end,
}
