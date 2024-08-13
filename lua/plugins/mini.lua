return {

  {
    'echasnovski/mini.ai',
    version = '*',
    event = 'VeryLazy',
    opts = {}
  },

  {
    'echasnovski/mini.pairs',
    version = '*',
    event = 'VeryLazy',
    opts = {},
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
