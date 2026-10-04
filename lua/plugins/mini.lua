return {
  {
    src = 'https://github.com/nvim-mini/mini.input',
    version = vim.version.range('*'),
    setup = function()
      require('mini.input').setup({})
    end,
  },
  {
    src = 'https://github.com/nvim-mini/mini.icons',
    version = vim.version.range('*'),
    setup = function()
      require('mini.icons').setup({})
    end,
  },
  {
    src = 'https://github.com/nvim-mini/mini.surround',
    version = vim.version.range('*'),
    setup = function()
      require('mini.surround').setup({})
    end,
  },
  {
    src = 'https://github.com/nvim-mini/mini.hipatterns',
    version = vim.version.range('*'),
    setup = function()
      require('mini.hipatterns').setup((function()
        return {
          highlighters = {
            -- Highlight standalone 'FIXME', 'HACK', 'TODO', 'NOTE'
            fixme = {
              pattern = '%f[%w]()FIXME()%f[%W]',
              group = 'MiniHipatternsFixme',
            },
            hack = {
              pattern = '%f[%w]()HACK()%f[%W]',
              group = 'MiniHipatternsHack',
            },
            todo = {
              pattern = '%f[%w]()TODO()%f[%W]',
              group = 'MiniHipatternsTodo',
            },
            note = {
              pattern = '%f[%w]()NOTE()%f[%W]',
              group = 'MiniHipatternsNote',
            },

            -- Highlight hex color strings (`#rrggbb`) using that color
            hex_color = require('mini.hipatterns').gen_highlighter.hex_color(),
          },
        }
      end)())
    end,
  },
  {
    src = 'https://github.com/nvim-mini/mini.cursorword',
    version = vim.version.range('*'),
    setup = function()
      require('mini.cursorword').setup({
        delay = 100,
      })
    end,
  },
  {
    src = 'https://github.com/nvim-mini/mini.indentscope',
    version = vim.version.range('*'),
    setup = function()
      require('mini.indentscope').setup((function()
        return {
          draw = {
            animation = require('mini.indentscope').gen_animation.none(),
          },
          options = {
            try_as_border = true,
          },
        }
      end)())
    end,
  },
  {
    src = 'https://github.com/nvim-mini/mini.pairs',
    version = vim.version.range('*'),
    setup = function()
      require('mini.pairs').setup({
        mappings = {
          [')'] = { action = 'close', pair = '()', neigh_pattern = '[^\\].' },
          [']'] = { action = 'close', pair = '[]', neigh_pattern = '[^\\].' },
          ['}'] = { action = 'close', pair = '{}', neigh_pattern = '[^\\].' },
          ['['] = {
            action = 'open',
            pair = '[]',
            neigh_pattern = '.[%s%z%)}%]]',
            register = { cr = false },
            -- foo|bar -> press '[' -> foo[bar
            -- foobar| -> press '[' -> foobar[]
            -- |foobar -> press '[' -> [foobar
            -- | foobar -> press '[' -> [] foobar
            -- foobar | -> press '[' -> foobar []
            -- {|} -> press '[' -> {[]}
            -- (|) -> press '[' -> ([])
            -- [|] -> press '[' -> [[]]
          },
          ['{'] = {
            action = 'open',
            pair = '{}',
            -- neigh_pattern = '.[%s%z%)}]',
            neigh_pattern = '.[%s%z%)}%]]',
            register = { cr = false },
            -- foo|bar -> press '{' -> foo{bar
            -- foobar| -> press '{' -> foobar{}
            -- |foobar -> press '{' -> {foobar
            -- | foobar -> press '{' -> {} foobar
            -- foobar | -> press '{' -> foobar {}
            -- (|) -> press '{' -> ({})
            -- {|} -> press '{' -> {{}}
          },
          ['('] = {
            action = 'open',
            pair = '()',
            -- neigh_pattern = '.[%s%z]',
            neigh_pattern = '.[%s%z%)]',
            register = { cr = false },
            -- foo|bar -> press '(' -> foo(bar
            -- foobar| -> press '(' -> foobar()
            -- |foobar -> press '(' -> (foobar
            -- | foobar -> press '(' -> () foobar
            -- foobar | -> press '(' -> foobar ()
          },
          -- Single quote: Prevent pairing if either side is a letter
          ['"'] = {
            action = 'closeopen',
            pair = '""',
            neigh_pattern = '[^%d%ua-eg-z\\][^%w]',
            register = { cr = false },
          },
          -- Single quote: Prevent pairing if either side is a letter
          ["'"] = {
            action = 'closeopen',
            pair = "''",
            neigh_pattern = '[^%d%ua-eg-z\\][^%w]',
            register = { cr = false },
          },
          -- Backtick: Prevent pairing if either side is a letter
          ['`'] = {
            action = 'closeopen',
            pair = '``',
            neigh_pattern = '[^%w\\][^%w]',
            register = { cr = false },
          },
        },
      })
    end,
  },
}
