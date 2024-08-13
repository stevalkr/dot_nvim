# dot nvim

My personal Neovim configuration, aimed at satisfying my usage needs while keeping it as lightweight as possible.

It summarizes the keymaps and usage habits that have been most suitable for me personally over the years.

![dot nvim](https://github.com/etherswangel/leetcode_go/assets/65963536/b9e4b972-5295-4bd8-afea-e99b1e4044d7)

## requirements

- [neovim](https://github.com/neovim/neovim) (version >= 0.10)
- [nerd fonts](https://github.com/ryanoasis/nerd-fonts) (recommended)
- [tree-sitter](https://github.com/tree-sitter/tree-sitter) (recommended)
- [kitty](https://sw.kovidgoyal.net/kitty/) (version >= 0.21, or any emulator supports XTVERSION escape codes)
- [fd](https://github.com/sharkdp/fd) (optional)
- [rg](https://github.com/BurntSushi/ripgrep) (optional)
- [xclip](https://github.com/astrand/xclip) (optional)
- [language servers](https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md) (optional)

## updates

- `:TSUpdate` Update installed tree-sitter parsers
- `:Lazy sync` Update plugins
- `$ brew upgrade neovim` Update neovim by your package manager

## usage

```
$ git clone https://github.com/etherswangel/dot_nvim.git ~/.config/nvim
$ nvim
```

## keymaps

### basic

| mode | keymap | usage |
| ---- | ------ | ----- |
| n | `u` | undo |
| n | `U` | redo |
| { i, t } | `jj` | normal mode |
| n | `<Esc>` | clear highlights |
| n | `*` | search current word |
| n | `<Space>` | select current word and expand |
| v | `y` | yank |
| v | `Y` | yank to system clipboard (need `xclip` for X11) |
| v | `<` | shift left |
| v | `>` | shift right |

### navigate

| mode | keymap | usage |
| ---- | ------ | ----- |
| n | `L` | next buffer |
| n | `H` | previous buffer |
| n | `<Tab>` | next tab |
| n | `<S-Tab>` | previous tab |
| n | `,0` | go to last tab |
| n | `,{1-9}` | go to nth tab |
| n | `[i` | go to indent scope top |
| n | `]i` | go to indent scope bottom |

### window

| mode | keymap | usage |
| ---- | ------ | ----- |
| n | `,w` | close tab |
| n | `,e` | close window |
| n | `,[` | move tab forward |
| n | `,]` | move tab backward |
| n | `st` | new empty tab |
| n | `ss` | current file in new tab |
| n | `sj` | split down |
| n | `sl` | split right |
| { n, t } | `<Ctrl-{ h, j, k, l }>` | to window |
| n | `s{ H, J, K, L }` | move window |
| n | `<Arrows>` | resize window |

### move

| mode | keymap | usage |
| ---- | ------ | ----- |
| n | `<Alt-{ j, k }>` | move page |
| n | `<Ctrl-u>` | move cursor up 10 lines |
| n | `<Ctrl-d>` | move cursor down 10 lines |
| i | `<Alt-{ h, j, k, l }>` | move cursor |
| i | `<Ctrl-a>` | first char in line |
| i | `<Ctrl-e>` | last char in line |
| v | `{J, K}` | move current line |

### fzf-lua

| mode | keymap | usage |
| ---- | ------ | ----- |
| n | `;;` | resume |
| n | `;a` | fzf builtin |
| n | `;f` | find files |
| { n, v } | `;g` | grep in workspace |
| n | `;b` | buffers |
| n | `;e` | open oil |
| n | `;E` | open oil in float |

### lsp

| mode | keymap | usage |
| ---- | ------ | ----- |
| n | `,cc` | switch source header (c/c++) |
| { n, v } | `,ca` | code actions |
| n | `,rn` | rename symbol |
| n | `,s` | document symbols |
| n | `,S` | workspace symbols |
| { n, v } | `,f` | format document |
| n | `,d` | show current diagnostic |
| n | `,D` | diagnostics |
| n | `[d` | previous diagnostic |
| n | `]d` | next diagnostic |
| n | `gd` | go to definition |
| n | `gi` | go to implementation |
| n | `gr` | go to references |
| n | `K` | hover |
| i | `<Ctrl-k>` | signature help |

### git

| mode | keymap | usage |
| ---- | ------ | ----- |
| n | `[h` | previous hunk |
| n | `]h` | next hunk |
| n | `,hb` | current line blame |
| n | `,hB` | blame line |
| n | `,hd` | diff |
| n | `,hD` | diff HEAD |
| n | `,hp` | preview hunk |
