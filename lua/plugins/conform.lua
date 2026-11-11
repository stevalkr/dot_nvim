local utils = require('utils')

-- Pyink stops at the first .git, so a workspace config above the repos is
-- never read. Pass the nearest one between the file and cwd instead.
local function pyink_config(_, ctx)
  local cwd = vim.fn.getcwd()
  if not vim.fs.relpath(cwd, ctx.dirname) then
    return {}
  end
  local config = vim.fs.find(function(name, path)
    if name ~= 'pyproject.toml' then
      return false
    end
    for line in io.lines(vim.fs.joinpath(path, name)) do
      if line:match('^%s*%[tool%.pyink[%]%.]') then
        return true
      end
    end
    return false
  end, {
    path = ctx.dirname,
    upward = true,
    stop = vim.fs.dirname(cwd),
    type = 'file',
  })[1]
  return config and { '--config', config } or {}
end

local function setup()
  local conform = require('conform')
  conform.setup({
    formatters = {
      pyink = { prepend_args = pyink_config },
    },
    formatters_by_ft = {
      js = { 'prettierd', lsp_format = 'fallback' },
      json = { 'prettierd', lsp_format = 'fallback' },
      lua = { 'stylua', lsp_format = 'fallback' },
      nix = { 'nixfmt', lsp_format = 'fallback' },
      rust = { 'rustfmt', lsp_format = 'fallback' },
      python = { 'pyink', lsp_format = 'fallback' },
      c = { 'clang-format', lsp_format = 'fallback' },
      cpp = { 'clang-format', lsp_format = 'fallback' },
      fish = { 'fish_indent', lsp_format = 'fallback' },
      cmake = { 'cmake-format', lsp_format = 'fallback' },
      markdown = { 'injected', lsp_format = 'fallback' },
    },
  })

  utils.keymap({ 'n', 'v' }, '<leader>f', function()
    conform.format({ async = true })
  end, 'Format code')
end

return {
  {
    src = 'https://github.com/stevearc/conform.nvim',
    setup = setup,
  },
}
