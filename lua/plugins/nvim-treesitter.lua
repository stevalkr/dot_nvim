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
  'toml',
  'vim',
  'vimdoc',
  'yaml',
}

local function build()
  local treesitter = require('nvim-treesitter')
  local function report(err, success)
    if err or success == false then
      vim.notify(
        'Treesitter parser build failed: ' .. tostring(err or 'see :messages'),
        vim.log.levels.ERROR
      )
    end
  end
  treesitter.install(servers):await(function(err, success)
    if err or success == false then
      report(err, success)
      return
    end
    treesitter.update(servers):await(report)
  end)
end

local function setup()
  local enabled = {}
  for _, language in ipairs(servers) do
    enabled[language] = true
  end
  vim.api.nvim_create_autocmd('FileType', {
    group = vim.api.nvim_create_augroup(
      'TreesitterHighlight',
      { clear = true }
    ),
    callback = function(args)
      local language =
        vim.treesitter.language.get_lang(vim.bo[args.buf].filetype)
      if
        language
        and enabled[language]
        and vim.treesitter.language.add(language)
      then
        vim.treesitter.start(args.buf, language)
        vim.bo[args.buf].indentexpr =
          "v:lua.require('nvim-treesitter').indentexpr()"
      end
    end,
  })
end

return {
  {
    src = 'https://github.com/nvim-treesitter/nvim-treesitter',
    setup = setup,
    build = build,
  },
  {
    src = 'https://github.com/nvim-treesitter/nvim-treesitter-context',
    dependencies = { 'nvim-treesitter' },
    setup = function()
      require('treesitter-context').setup({
        max_lines = 3,
        multiline_threshold = 1,
      })
    end,
  },
}
