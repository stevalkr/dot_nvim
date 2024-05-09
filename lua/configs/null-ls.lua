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
      null_ls.builtins.diagnostics.markdownlint,
      null_ls.builtins.diagnostics.fish,

      null_ls.builtins.formatting.nixpkgs_fmt,
      null_ls.builtins.formatting.cmake_format,
    }
  })
end

return M

