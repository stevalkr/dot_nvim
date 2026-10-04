local function setup()
  require('null-ls').setup((function()
    local null_ls = require('null-ls')
    return {
      sources = {
        -- null_ls.builtins.code_actions.gitsigns.with({
        --   config = {
        --     filter_actions = function(title)
        --       return title:lower():match('blame') == nil
        --     end,
        --   },
        -- }),
        -- null_ls.builtins.code_actions.refactoring.with({
        --   filetypes = { 'c', 'cpp', 'go', 'javascript', 'lua', 'python', 'typescript' }
        -- }),

        null_ls.builtins.diagnostics.codespell,
        null_ls.builtins.diagnostics.markdownlint,
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
