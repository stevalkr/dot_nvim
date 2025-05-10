local utils = require('utils')

-- user commands
vim.api.nvim_create_user_command('SaveSession',
  utils.save_session,
  { nargs = 0 }
)

-- auto groups
utils.augroup({
  relative_number = {
    {
      event = 'InsertEnter',
      callback = function()
        vim.opt.relativenumber = false
      end
    },
    {
      event = 'InsertLeave',
      callback = function()
        vim.opt.relativenumber = true
      end
    }
  },

  highlight_current_line = {
    {
      event = { 'WinLeave', 'BufLeave', 'InsertEnter' },
      callback = function()
        vim.opt.cursorline = false
      end
    },
    {
      event = { 'WinEnter', 'BufEnter', 'InsertLeave' },
      callback = function()
        vim.opt.cursorline = true
      end
    },
  },

  wins = {
    -- check if file changed when its window is focus, more eager than 'autoread'
    {
      event = 'FocusGained',
      command = [[checktime]]
    },
    {
      event = 'VimResized',
      callback = function ()
        local tab = vim.api.nvim_get_current_tabpage()
        vim.cmd([[tabdo wincmd =]])
        vim.api.nvim_set_current_tabpage(tab)
      end
    }
  },

  last_edited = {
    {
      event = 'BufReadPost',
      callback = function(opts)
        if vim.tbl_contains({ 'quickfix', 'nofile', 'help' },
              vim.bo.buftype) then
          return
        end

        if vim.tbl_contains({ 'gitcommit', 'gitrebase', 'svn', 'hgcommit' },
              vim.bo.filetype) then
          vim.cmd([[normal! gg]])
          return
        end

        if vim.api.nvim_win_get_cursor(0)[1] > 1 then
          return
        end

        local ft = vim.bo[opts.buf].filetype
        local last_line = vim.api.nvim_buf_get_mark(opts.buf, '"')[1]
        local buff_last_line = vim.api.nvim_buf_line_count(opts.buf)

        if not (ft:match('commit') and ft:match('rebase'))
            and last_line > 0
            and last_line <= buff_last_line then
          local win_last_line = vim.fn.line('w$')
          local win_first_line = vim.fn.line('w0')

          if win_last_line == buff_last_line then
            vim.cmd [[normal! g`"]]
          elseif buff_last_line - last_line > ((win_last_line - win_first_line) / 2) - 1 then
            vim.cmd [[normal! g`"zz]]
          else
            vim.cmd [[normal! G'"<c-e>]]
          end
        end
      end
    },
  },

  tailing_spaces = {
    {
      event = 'BufWritePre',
      callback = function()
        local save_cursor = vim.fn.getpos('.')
        vim.cmd([[%s/\s\+$//e]])
        vim.fn.setpos('.', save_cursor)
      end,
    },
  },

  highlight_yank = {
    {
      event = 'TextYankPost',
      callback = function()
        vim.highlight.on_yank({ higroup = 'IncSearch', timeout = 300 })
      end
    }
  },

  comment = {
    {
      event = 'FileType',
      pattern = 'c,cpp',
      callback = function()
        vim.bo.commentstring = [[// %s]]
      end
    }
  },

  save_cwd = {
    {
      event = 'VimLeave',
      callback = function()
        local path = vim.env.TMPDIR .. '/vim_cwd'
        local file = io.open(path, 'w')
        if file then
          file:write(vim.fn.getcwd())
          file:flush()
          file:close()
        else
          vim.notify('Error: Unable to write to ' .. path, vim.log.levels.ERROR)
        end
      end
    }
  },

  hide_copilot_suggestion = {
    {
      event = 'User',
      pattern = 'BlinkCmpMenuOpen',
      callback = function()
        if utils.has_plugin('copilot.lua') then
          require('copilot.suggestion').dismiss()
        end
        vim.b.copilot_suggestion_hidden = true
      end
    },
    {
      event = 'User',
      pattern = 'BlinkCmpMenuClose',
      callback = function()
        vim.b.copilot_suggestion_hidden = false
      end
    }
  },

  roslaunch = {
    {
      event = 'BufEnter',
      pattern = '*.launch',
      callback = function()
        vim.bo.filetype = 'xml'
      end
    }
  }
})
