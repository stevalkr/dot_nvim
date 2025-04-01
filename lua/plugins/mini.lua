return {

  {
    'echasnovski/mini.ai',
    version = '*',
    event = 'VeryLazy',
    opts = {}
  },

  {
    'echasnovski/mini.icons',
    version = '*',
    event = 'VeryLazy',
    opts = {}
  },

  {
    'echasnovski/mini.pairs',
    version = '*',
    event = 'VeryLazy',
    opts = {
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
          neigh_pattern = '[^%w\\][^%w]',
          register = { cr = false },
        },
        -- Single quote: Prevent pairing if either side is a letter
        ["'"] = {
          action = 'closeopen',
          pair = "''",
          neigh_pattern = '[^%w\\][^%w]',
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
    },
  },

  {
    'echasnovski/mini.surround',
    version = '*',
    event = 'VeryLazy',
    opts = {},
  },

  {
    'echasnovski/mini.indentscope',
    version = '*',
    event = 'VeryLazy',
    opts = function()
      return {
        draw = {
          animation = require('mini.indentscope').gen_animation.none()
        },
        options = {
          try_as_border = true
        }
      }
    end
  },

  {
    'echasnovski/mini.cursorword',
    version = '*',
    event = 'VeryLazy',
    opts = {
      delay = 100,
    }
  },

  {
    'echasnovski/mini.sessions',
    version = '*',
    opts = {
      autoread = true,
      autowrite = false,
      file = '.cache/session.vim',
      directory = '',
      force = { read = false, write = true, delete = true },
    }
  },

}
