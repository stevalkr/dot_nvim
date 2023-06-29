vim.loader.enable()

vim.opt.mouse = 'a'
vim.opt.syntax = 'ON'
vim.opt.scrolloff = 5
vim.opt.history = 2000
vim.opt.encoding = 'UTF-8'
vim.opt.showcmd = true
vim.opt.cursorline = true
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.signcolumn = 'auto:1'
vim.opt.showmatch = true
vim.opt.termguicolors = true

vim.opt.confirm = true
vim.opt.undofile = true

vim.opt.smartcase = true
vim.opt.ignorecase = true

vim.opt.splitright = true
vim.opt.splitbelow = true

vim.opt.cmdheight = 2
vim.opt.helpheight = 12
vim.opt.previewheight = 12
vim.opt.showtabline = 2

vim.opt.smarttab = true
vim.opt.expandtab = true
vim.opt.autoindent = true
vim.opt.smartindent = true
vim.opt.tabstop = 8
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.shiftround = true

vim.opt.sessionoptions = 'blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions'

vim.opt.wildignore =
'.git,.hg,.svn,*.pyc,*.o,*.out,*.jpg,*.jpeg,*.png,*.gif,*.zip,**/tmp/**,*.DS_Store,**/node_modules/**,**/bower_modules/**'
vim.opt.wildignorecase = true

vim.opt.foldenable = false
vim.opt.foldmethod = 'expr'
vim.opt.foldexpr = 'nvim_treesitter#foldexpr()'

vim.opt.foldtext = [[v:lua.require('utils').foldtext()]]


local function augroup(definitions)
  for group_name, definition in pairs(definitions) do
    vim.api.nvim_create_augroup(group_name, { clear = true })
    for _, def in ipairs(definition) do
      vim.api.nvim_create_autocmd(def.event, {
        pattern = def.pattern,
        group = group_name,
        command = def.command,
        callback = def.callback
      })
    end
  end
end

augroup({

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
    -- equalize window dimensions when resizing vim window
    {
      event = 'VimResized',
      command = [[tabdo wincmd =]]
    },
  },

  last_edited = {
    {
      event = 'BufReadPost',
      callback = function(opts)
        if vim.tbl_contains({ "quickfix", "nofile", "help" },
              vim.bo.buftype) then
          return
        end

        if vim.tbl_contains({ "gitcommit", "gitrebase", "svn", "hgcommit" },
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
          local win_last_line = vim.fn.line("w$")
          local win_first_line = vim.fn.line("w0")

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
        local save_cursor = vim.fn.getpos(".")
        vim.cmd([[%s/\s\+$//e]])
        vim.fn.setpos(".", save_cursor)
      end,
    },
  },

  highlight_yank = {
    {
      event = 'TextYankPost',
      callback = function()
        vim.highlight.on_yank({ higroup = "IncSearch", timeout = 300 })
      end
    }
  },

  comment = {
    -- {
    --   event = 'FileType',
    --   pattern = 'c,cpp,cs,java',
    --   command = [[setlocal commentstring=//\ %s]],
    -- }
  },

  auto_session = {
    {
      event = 'UIEnter',
      callback = function()
        if vim.bo.filetype ~= '' then
          return
        end

        if vim.api.nvim_buf_get_lines(0, 0, -1, false)[1] == '' then
          local session_lens = require('auto-session.session-lens')
          if session_lens then
            session_lens.search_session()
          end
        end
      end,
    }
  }

})
