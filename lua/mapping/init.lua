vim.cmd([[

" -------------
" -- general --
" -------------

nnoremap <silent> j gj
nnoremap <silent> k gk
nnoremap <silent> gj j
nnoremap <silent> gk k

inoremap <silent> jj <Esc>
tnoremap <silent> jj <C-\><C-n>

nnoremap <silent> * *``
nnoremap <silent> U <C-R>
nnoremap <silent> <Space> viw
nnoremap <silent> <Esc> <Cmd>nohlsearch<CR>

nnoremap <silent> n nzz
nnoremap <silent> N Nzz

nnoremap <silent> H <Cmd>bprevious<CR>
nnoremap <silent> L <Cmd>bnext<CR>
nnoremap <silent> <S-Tab> <Cmd>tabprevious<CR>
nnoremap <silent> <Tab> <Cmd>tabnext<CR>

nnoremap <silent> <C-o> <C-o>zz
nnoremap <silent> <C-i> <C-i>zz

nnoremap <silent> <C-e> <C-^>

nnoremap <silent> zj zMzv


" ------------
" -- window --
" ------------

nnoremap <silent> <leader>w <Cmd>tabclose<CR>
nnoremap <silent> <leader>e <Cmd>quit<CR>

nnoremap <silent> <leader>1 1gt
nnoremap <silent> <leader>2 2gt
nnoremap <silent> <leader>3 3gt
nnoremap <silent> <leader>4 4gt
nnoremap <silent> <leader>5 5gt
nnoremap <silent> <leader>6 6gt
nnoremap <silent> <leader>7 7gt
nnoremap <silent> <leader>8 8gt
nnoremap <silent> <leader>9 9gt
nnoremap <silent> <leader>0 <Cmd>tablast<CR>

nnoremap <silent> <leader>[ <Cmd>tabmove -1<CR>
nnoremap <silent> <leader>] <Cmd>tabmove +1<CR>

nnoremap <silent> ss <Cmd>tabnew %:p<CR>
nnoremap <silent> st <Cmd>tabnew<CR>
nnoremap <silent> sj <Cmd>split<CR>
nnoremap <silent> sl <Cmd>vertical split<CR>

nnoremap <silent> <C-h> <C-w>h
nnoremap <silent> <C-j> <C-w>j
nnoremap <silent> <C-k> <C-w>k
nnoremap <silent> <C-l> <C-w>l

nnoremap <silent> sH <C-w>H
nnoremap <silent> sJ <C-w>J
nnoremap <silent> sK <C-w>K
nnoremap <silent> sL <C-w>L

nnoremap <silent> <Left> <Cmd>vertical resize +1<CR>
nnoremap <silent> <Right> <Cmd>vertical resize -1<CR>
nnoremap <silent> <Up> <Cmd>resize -1<CR>
nnoremap <silent> <Down> <Cmd>resize +1<CR>


" --------------
" -- terminal --
" --------------

tnoremap <silent> <ESC> <C-\><C-n>
tnoremap <silent> <C-h> <C-\><C-n><C-w>h
tnoremap <silent> <C-j> <C-\><C-n><C-w>j
tnoremap <silent> <C-k> <C-\><C-n><C-w>k
tnoremap <silent> <C-l> <C-\><C-n><C-w>l


" ----------
" -- move --
" ----------

nnoremap <silent> <A-j> <C-y>
nnoremap <silent> <A-k> <C-e>

inoremap <silent> <A-h> <Left>
inoremap <silent> <A-j> <Down>
inoremap <silent> <A-k> <Up>
inoremap <silent> <A-l> <Right>
inoremap <silent> <C-a> <C-o>I
inoremap <silent> <C-e> <C-o>A

nnoremap <silent> <C-u> 10kzz
nnoremap <silent> <C-d> 10jzz
vnoremap <silent> <C-u> 10kzz
vnoremap <silent> <C-d> 10jzz


" ----------
" -- copy --
" ----------

vnoremap <silent> Y "+y

nnoremap <silent> x "_x
nnoremap <silent> X "_X
nnoremap <silent> D "_D
nnoremap <silent> C "_C
nnoremap <silent> cc "_cc

vnoremap <silent> c "_c
vnoremap <silent> p "_dP


" ------------
" -- visual --
" ------------

vnoremap <silent> < <gv
vnoremap <silent> > >gv

vnoremap <silent> J :move '>+1<CR>gv-gv
vnoremap <silent> K :move '<-2<CR>gv-gv


]])

