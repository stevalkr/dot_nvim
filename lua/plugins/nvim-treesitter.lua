return {

  'nvim-treesitter/nvim-treesitter',
  lazy = false,
  branch = 'main',
  build = function()
    require('nvim-treesitter.install').update()
  end,

  config = function()
    local servers = {
      'c', 'lua', 'vim', 'vimdoc', 'query',
      'cpp', 'python', 'elixir', 'rust', 'go',
      'cmake', 'yaml', 'json', 'bash', 'comment',
      'markdown', 'markdown_inline',
    }

    require('nvim-treesitter').install(servers)

    for _, server in ipairs(servers) do
      vim.api.nvim_create_autocmd('FileType', {
        pattern = { server },
        callback = function() vim.treesitter.start() end,
      })
    end
  end

}
