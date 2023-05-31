local M = {}

M.config = function()
  require('nvim-treesitter.configs').setup {
    ensure_installed = {
      'c', 'lua', 'vim', 'vimdoc', 'query',
      'cpp', 'python', 'elixir', 'rust', 'go',
      'cmake', 'yaml', 'json', 'bash', 'comment',
      'markdown', 'markdown_inline',
      -- 'typescript', 'javascript', 'eex', 'heex',
    },

    sync_install = false,
    auto_install = true,

    highlight = {
      enable = true,
      disable = function(lang, buf)
        local max_filesize = 100 * 1024 -- 100 KB
        local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
        if ok and stats and stats.size > max_filesize then
          return true
        end
      end,
      additional_vim_regex_highlighting = false,
    },

    incremental_selection = {
      enable = true,
      keymaps = {
        init_selection = '<cr>',
        node_incremental = '<space>',
        scope_incremental = '<cr>',
        node_decremental = '<bs>',
      },
    },
  }
end

return M
