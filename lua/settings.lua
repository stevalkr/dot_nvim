vim.o.mouse = 'a'
vim.o.magic = true
vim.o.encoding = 'utf-8'
vim.o.wildignorecase = true
vim.o.wildignore = '.git,.hg,.svn,*.pyc,*.o,*.out,*.jpg,*.jpeg,*.png,*.gif,*.zip,**/tmp/**,*.DS_Store,**/node_modules/**,**/bower_modules/**'
vim.o.backup = false
vim.o.writebackup = false
vim.o.swapfile = false
vim.o.history = 2000
vim.o.shiftround = true
vim.o.updatetime = 100
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.splitright = true
vim.o.splitbelow = true
vim.o.scrolloff = 5
vim.o.cursorline = true
vim.o.cursorcolumn = false
vim.o.showtabline = 2
vim.o.helpheight = 12
vim.o.previewheight = 12
vim.o.showcmd = true
vim.o.cmdheight = 2
vim.o.autoread = true
vim.o.autowrite = true
vim.o.confirm = true
vim.o.undofile = true
vim.o.syntax = 'on'
vim.o.synmaxcol = 2500
vim.o.smarttab = true
vim.o.expandtab = true
vim.o.autoindent = true
vim.o.smartindent = true
vim.o.tabstop = 2
vim.o.shiftwidth = 2
vim.o.softtabstop = 2
vim.o.ruler = true
vim.o.number = true
vim.o.relativenumber = true
vim.o.signcolumn = 'auto:1'
vim.o.hlsearch = true
vim.o.showmatch = true
vim.o.laststatus = 2
vim.o.termguicolors = true

vim.g.mapleader = ','
vim.g.cursorhold_updatetime = 100

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
      "InsertEnter",
      "*", [[set norelativenumber]]
    },
    {
      "InsertLeave",
      "*", [[set relativenumber]]
    }
  },
  wins = {
  -- highlight_current_line
    {
      "WinLeave,BufLeave,InsertEnter",
      "*", [[if &cursorline && &filetype !~# '^\(dashboard\|clap_\)' && ! &pvw | setlocal nocursorline | endif]],
    },
    {
      "WinEnter,BufEnter,InsertLeave",
      "*", [[if ! &cursorline && &filetype !~# '^\(dashboard\|clap_\)' && ! &pvw | setlocal cursorline | endif]],
    },
    -- Check if file changed when its window is focus, more eager than 'autoread'
    {
      "FocusGained",
      "*", [[checktime]]
    },
    -- Equalize window dimensions when resizing vim window
    {
      "VimResized",
      "*", [[tabdo wincmd =]]
    },
  },
  bufs = {
  -- last_edit
    {
      "BufReadPost",
      "*", [[if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif]]
    },
  -- remove_spaces
    {
      "BufWritePre",
      "*", [[:%s/\s\+$//e]]
    },
  -- auto_change_directory
    {
      "BufEnter",
      "*", [[silent! lcd %:p:h]]
    }
  },
  yank = {
  -- highlight yank
    {
      "TextYankPost",
      "*", [[silent! lua vim.highlight.on_yank({higroup="IncSearch", timeout=300})]],
    }
  }
})
