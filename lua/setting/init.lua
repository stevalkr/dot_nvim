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


local function nvim_create_augroups(definitions)
  for group_name, definition in pairs(definitions) do
    vim.api.nvim_command('augroup ' .. group_name)
    vim.api.nvim_command('autocmd!')
    for _, def in ipairs(definition) do
      local command = table.concat(vim.tbl_flatten({ 'autocmd', def }), ' ')
      vim.api.nvim_command(command)
    end
    vim.api.nvim_command('augroup END')
  end
end

nvim_create_augroups({
  inserts = {
    -- relative_number
    {
      'InsertEnter',
      '*', [[set norelativenumber]]
    },
    {
      'InsertLeave',
      '*', [[set relativenumber]]
    }
  },
  wins = {
    -- highlight_current_line
    {
      'WinLeave,BufLeave,InsertEnter',
      '*', [[if &cursorline && &filetype !~# '^\(dashboard\|clap_\)' && ! &pvw | setlocal nocursorline | endif]],
    },
    {
      'WinEnter,BufEnter,InsertLeave',
      '*', [[if ! &cursorline && &filetype !~# '^\(dashboard\|clap_\)' && ! &pvw | setlocal cursorline | endif]],
    },
    -- check if file changed when its window is focus, more eager than 'autoread'
    {
      'FocusGained',
      '*', [[checktime]]
    },
    -- equalize window dimensions when resizing vim window
    {
      'VimResized',
      '*', [[tabdo wincmd =]]
    },
  },
  bufs = {
    -- last_edit
    {
      'BufReadPost',
      '*', [[if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif]]
    },
    -- remove_spaces
    {
      'BufWritePre',
      '*', [[:%s/\s\+$//e]]
    },
  },
  yank = {
    -- highlight yank
    {
      'TextYankPost',
      '*', [[silent! lua vim.highlight.on_yank({higroup="IncSearch", timeout=300})]],
    }
  },
  comment = {
    -- set cpp line comment
    -- {
    --   'FileType',
    --   'c,cpp,cs,java', [[setlocal commentstring=//\ %s]],
    -- }
  },
})

vim.api.nvim_create_autocmd('UIEnter', {
  callback = function()
    if vim.bo.filetype ~= '' then -- Check if the buffer has a filetype
      return
    end
    -- If it doesn't we check if it's empty
    if vim.api.nvim_buf_get_lines(0, 0, -1, false)[1] == '' then
      local session_lens = require('auto-session.session-lens')
      if session_lens then
        session_lens.search_session()
      end
    end
  end,
})

local M = {}
M.use_treesitter_fold = function()
  vim.opt.foldenable = false
  vim.opt.foldmethod = 'expr'
  vim.opt.foldexpr = 'nvim_treesitter#foldexpr()'
end
return M
