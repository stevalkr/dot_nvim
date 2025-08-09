local utils = require('utils')

-- vim settings
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

vim.opt.cmdheight = 1
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

vim.opt.sessionoptions =
  'blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions,globals'

vim.opt.diffopt =
  'internal,filler,closeoff,indent-heuristic,linematch:60,algorithm:histogram'

vim.opt.wildignore =
  '.git,.hg,.svn,*.pyc,*.o,*.out,*.jpg,*.jpeg,*.png,*.gif,*.zip,**/tmp/**,*.DS_Store,**/node_modules/**,**/bower_modules/**'
vim.opt.wildignorecase = true

vim.opt.foldenable = true
vim.opt.foldlevel = 99
vim.opt.foldmethod = 'expr'
vim.opt.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
vim.opt.foldtext = ''

-- neovide settings
if vim.g.neovide then
  vim.opt.linespace = 6
  vim.o.winblend = 50
  vim.g.neovide_floating_blur_amount_x = 3.0
  vim.g.neovide_floating_blur_amount_y = 3.0
  vim.g.neovide_transparency = 0.95
  vim.g.neovide_hide_mouse_when_typing = true
  vim.g.neovide_theme = 'auto'
  vim.g.neovide_scroll_animation_length = 0.2
  vim.g.neovide_cursor_animation_length = 0
  vim.g.neovide_input_macos_option_key_is_meta = 'only_left'
  utils.keymap({ 'v', 's', 'x' }, '<D-c>', '"+y', 'Copy to system clipboard')
  utils.keymap(
    { 'n', 'v', 's', 'x', 'o', 'i', 'l', 'c', 't' },
    '<D-v>',
    function()
      vim.api.nvim_paste(vim.fn.getreg('+'), true, -1)
    end,
    'Paste from system clipboard'
  )
  vim.g.neovide_scale_factor = 1.0
  local change_scale_factor = function(delta)
    vim.g.neovide_scale_factor = vim.g.neovide_scale_factor * delta
  end
  utils.keymap('n', '<D-=>', function()
    change_scale_factor(1.25)
  end, 'Increase scale factor')
  utils.keymap('n', '<D-->', function()
    change_scale_factor(0.8)
  end, 'Decrease scale factor')
end
