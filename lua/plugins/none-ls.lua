local function setup()
  require('null-ls').setup((function()
    local null_ls = require('null-ls')
    return {
      sources = {
        null_ls.builtins.diagnostics.codespell.with({
          -- codespell reads .codespellrc from its own cwd, not the null-ls root.
          cwd = function()
            return vim.fn.getcwd()
          end,
        }),
        null_ls.builtins.diagnostics.markdownlint.with({
          extra_args = { '--disable', 'MD013' },
        }),
        null_ls.builtins.diagnostics.fish,
        null_ls.builtins.diagnostics.zsh,
      },
    }
  end)())
end

return {
  {
    src = 'https://github.com/nvimtools/none-ls.nvim',
    dependencies = { 'plenary.nvim' },
    setup = setup,
  },
}
