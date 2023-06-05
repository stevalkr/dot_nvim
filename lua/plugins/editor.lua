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
    opts = {
      window = { blend = 0 },
    }
  },

  {
    'RRethy/vim-illuminate',
    event = { 'BufReadPost', 'BufNewFile' },
    config = function(_, _opts)
      local kopts = { noremap = true, silent = true }
      vim.keymap.set('n', '[[', function()
        require('illuminate').goto_prev_reference()
      end, kopts)
      vim.keymap.set('n', ']]', function()
        require('illuminate').goto_next_reference()
      end, kopts)
    end
  },

  {
    'rmagatti/auto-session',
    opts = {
      auto_session_suppress_dirs = { '~/', '~/*', '/', '/*' },
      auto_session_allowed_dirs = { '~/.config/*' },
      auto_session_use_git_branch = true,
      session_lens = {
        load_on_setup = true,
        previewer = true,
        initial_mode = 'normal',
        attach_mappings = function(_, map)
          local Actions = require('auto-session.session-lens.actions')
          require('telescope.actions').select_default:replace(Actions.source_session)
          map("n", "dd", Actions.delete_session)
          map("n", ";s", Actions.alternate_session)
          return true
        end,
      },
    },
    config = function(_, opts)
      -- opts['session_lens'] = vim.tbl_deep_extend('force', opts['session_lens'],
      --   require('telescope.themes').get_cursor(opts['session_lens'].theme_conf))
      require('auto-session').setup(opts)
      require('telescope').load_extension('session-lens')
      local kopts = { noremap = true, silent = true }
      vim.keymap.set('n', ';s', require("auto-session.session-lens").search_session, kopts)
    end
  },

  {
    'lewis6991/gitsigns.nvim',
    event = { 'BufReadPre', 'BufNewFile' },
    opts = {
      on_attach = function(bufnr)
        local gs = package.loaded.gitsigns
        local kopts = { noremap = true, silent = true, buffer = bufnr }

        -- Actions
        vim.keymap.set('n', '<leader>hs', gs.stage_hunk, kopts)
        vim.keymap.set('n', '<leader>hr', gs.reset_hunk, kopts)
        vim.keymap.set('v', '<leader>hs', function() gs.stage_hunk { vim.fn.line('.'), vim.fn.line('v') } end, kopts)
        vim.keymap.set('v', '<leader>hr', function() gs.reset_hunk { vim.fn.line('.'), vim.fn.line('v') } end, kopts)
        vim.keymap.set('n', '<leader>hS', gs.stage_buffer, kopts)
        vim.keymap.set('n', '<leader>hu', gs.undo_stage_hunk, kopts)
        vim.keymap.set('n', '<leader>hR', gs.reset_buffer, kopts)
        vim.keymap.set('n', '<leader>hp', gs.preview_hunk, kopts)
        vim.keymap.set('n', '<leader>hb', function() gs.blame_line { full = true } end, kopts)
        vim.keymap.set('n', '<leader>tb', gs.toggle_current_line_blame, kopts)
        vim.keymap.set('n', '<leader>hd', gs.diffthis, kopts)
        vim.keymap.set('n', '<leader>hD', function() gs.diffthis('~') end, kopts)
        vim.keymap.set('n', '<leader>td', gs.toggle_deleted, kopts)

        -- Text object
        vim.keymap.set({ 'o', 'x' }, 'ih', '<Cmd>Gitsigns select_hunk<CR>', kopts)

        kopts.expr = true
        -- Navigation
        vim.keymap.set('n', ']h', function()
          if vim.wo.diff then return ']h' end
          vim.schedule(function() gs.next_hunk() end)
          return '<Ignore>'
        end, kopts)

        vim.keymap.set('n', '[h', function()
          if vim.wo.diff then return '[h' end
          vim.schedule(function() gs.prev_hunk() end)
          return '<Ignore>'
        end, kopts)
      end
    }
  }

}
