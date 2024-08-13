return {

  'nvim-treesitter/nvim-treesitter',
  lazy = false,
  build = function()
    require('nvim-treesitter.install').update({ with_sync = true })
  end,

  config = function()
    require('nvim-treesitter.configs').setup({
      ensure_installed = {
        'c', 'lua', 'vim', 'vimdoc', 'query',
        'cpp', 'python', 'elixir', 'rust', 'go',
        'cmake', 'yaml', 'json', 'bash', 'comment',
        'markdown', 'markdown_inline',
      },

      sync_install = false,
      auto_install = true,

      highlight = {
        enable = true,
        disable = function(lang, buf)
          local max_filesize = 100 * 1024 -- 100 KB
          local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(buf))
          if ok and stats and stats.size > max_filesize then
            return true
          end
        end,
        additional_vim_regex_highlighting = false,
      },

      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = '<CR>',
          node_incremental = '<Space>',
          scope_incremental = '<CR>',
          node_decremental = '<BS>',
        },
      },

      indent = {
        enable = true
      }
    })
  end

}
