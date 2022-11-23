local map = vim.api.nvim_set_keymap
local default = { noremap = false, silent = true }
local noremap = { noremap = true, silent = true }

-- general
map('n', '*', [[*``]], noremap)
map('n', 'U', [[<c-R>]], noremap)
map('v', '<c-c>', [["+y]], noremap)
map('n', '<esc>', [[<esc>:noh<cr>]], noremap)
map('n', '<space>', [[viw]], noremap)
map('i', 'jj', [[<esc>]], noremap)

-- avoid copy
map('n', 'x', [["_x]], noremap)
map('n', 'X', [["_X]], noremap)
map('n', 'D', [["_D]], noremap)
map('n', 'C', [["_C]], noremap)
map('n', 'cc', [["_cc]], noremap)
-- map('n', 'dd', [["_dd]], noremap)
map('v', 'c', [["_c]], noremap)
-- map('v', 'd', [["_d]], noremap)

-- windows
map('n', '<c-s-q>', [[:qa<cr>]], noremap)
map('n', '<leader>w', [[:bp | bd #<cr>]], noremap)
map('n', '<leader>e', [[:q<cr>]], noremap)

map('n', 's', [[<c-w>]], default)
map('n', '<c-w>j', [[:split<cr>]], noremap)
map('n', '<c-w>l', [[:vsplit<cr>]], noremap)

map('n', '=', [[:vertical resize +1<cr>]], noremap)
map('n', '-', [[:vertical resize -1<cr>]], noremap)
map('n', '<a-=>', [[:resize +1<cr>]], noremap)
map('n', '<a-->', [[:resize -1<cr>]], noremap)

-- terminal
map('t', '<leader><esc>', [[<c-\><c-n>]], noremap)
map('t', '<leader><c-h>', [[<c-\><c-n><c-W>h]], noremap)
map('t', '<leader><c-j>', [[<c-\><c-n><c-W>j]], noremap)
map('t', '<leader><c-k>', [[<c-\><c-n><c-W>k]], noremap)
map('t', '<leader><c-l>', [[<c-\><c-n><c-W>l]], noremap)

-- move
map('n', '<c-h>', [[<c-w>h]], noremap)
map('n', '<c-j>', [[<c-w>j]], noremap)
map('n', '<c-k>', [[<c-w>k]], noremap)
map('n', '<c-l>', [[<c-w>l]], noremap)

map('n', '<a-j>', [[<c-y>]], noremap)
map('n', '<a-k>', [[<c-e>]], noremap)
map('i', '<a-h>', [[<left>]], noremap)
map('i', '<a-j>', [[<down>]], noremap)
map('i', '<a-k>', [[<up>]], noremap)
map('i', '<a-l>', [[<right>]], noremap)

map('n', '<c-u>', [[10k]], noremap)
map('n', '<c-d>', [[10j]], noremap)
map('n', '<pageup>', [[<c-u>]], noremap)
map('n', '<pagedown>', [[<c-d>]], noremap)
-- map('v', '<c-u>', [[10k]], noremap)
-- map('v', '<c-d>', [[10j]], noremap)
map('v', '<pageup>', [[10k]], noremap)
map('v', '<pagedown>', [[10j]], noremap)
