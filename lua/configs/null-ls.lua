local M = {}

M.config = function(_, _opts)
  local null_ls = require('null-ls')
  null_ls.setup({
    sources = {
      null_ls.builtins.code_actions.gitsigns.with({
        config = {
          filter_actions = function(title)
            return title:lower():match('blame') == nil
          end,
        },
      }),
      null_ls.builtins.diagnostics.codespell,
    }
  })
end

return M

