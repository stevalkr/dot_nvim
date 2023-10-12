local utils = require('utils')

return {

  {
    'echasnovski/mini.pairs',
    version = '*',
    event = 'VeryLazy',
    opts = {},
  },

  {
    'echasnovski/mini.comment',
    version = '*',
    event = 'VeryLazy',
    opts = {
      options = {
        ignore_blank_line = true,
        custom_commentstring = function(_)
          local filetype = vim.bo.filetype
          for _, s in pairs({ 'cpp', 'c' }) do
            if filetype == s then
              return [[// %s]]
            end
          end
        end,
      }
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
    opts = function(_, _opts)
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
    'j-hui/fidget.nvim',
    event = 'BufReadPost',
    tag = 'legacy',
    opts = {
      window = { blend = 0 },
    }
  },

  {
    'RRethy/vim-illuminate',
    event = { 'BufReadPost', 'BufNewFile' },
    config = function(_, _opts)
      utils.keymap('n', '[[', function()
        require('illuminate').goto_prev_reference()
      end, 'Previous ref')
      utils.keymap('n', ']]', function()
        require('illuminate').goto_next_reference()
      end, 'Next ref')
    end
  },

  {
    'willothy/flatten.nvim',
    lazy = false,
    opts = {
      window = {
        open = 'tab'
      },
      nest_if_no_args = true,
    },
  },

  {
    'rmagatti/auto-session',
    opts = {
      auto_session_suppress_dirs = { '~/', '~/*', '/', '/*' },
      auto_session_allowed_dirs = { '~/.config/*', '/home/share/config/*' },
      auto_session_use_git_branch = true,
      session_lens = {
        load_on_setup = true,
        previewer = true,
        initial_mode = 'normal',
        attach_mappings = function(_, map)
          local Actions = require('auto-session.session-lens.actions')
          require('telescope.actions').select_default:replace(Actions.source_session)
          map('n', 'dd', Actions.delete_session)
          map('n', ';s', Actions.alternate_session)
          return true
        end,
      },
    },
    config = function(_, opts)
      require('auto-session').setup(opts)
      require('telescope').load_extension('session-lens')
      utils.keymap('n', ';s', require('auto-session.session-lens').search_session, 'Sessions')
    end
  },

  {
    'lewis6991/gitsigns.nvim',
    event = { 'BufReadPre', 'BufNewFile' },
    config = require('configs.gitsigns').config
  }

}
