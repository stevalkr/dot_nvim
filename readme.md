# dot nvim

My personal Neovim configuration, aimed at satisfying my usage needs while keeping it as lightweight as possible.

It summarizes the keymaps and usage habits that have been most suitable for me personally over the years.

![dot nvim](https://github.com/etherswangel/leetcode_go/assets/65963536/b9e4b972-5295-4bd8-afea-e99b1e4044d7)

## requirements

- [neovim](https://github.com/neovim/neovim) (version >= 0.13)
- [nerd fonts](https://github.com/ryanoasis/nerd-fonts) (recommended)
- [tree-sitter](https://github.com/tree-sitter/tree-sitter) (recommended)
- [kitty](https://sw.kovidgoyal.net/kitty/) (version >= 0.21, or any emulator supports XTVERSION escape codes)
- [fd](https://github.com/sharkdp/fd) (optional)
- [rg](https://github.com/BurntSushi/ripgrep) (optional)
- [xclip](https://github.com/astrand/xclip) (optional)
- [language servers](https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md) (optional)

## updates

- `:TSUpdate` Update installed tree-sitter parsers
- `:packupdate` Review plugin updates; `:write` applies them and `:quit` discards them
- `:restart` Restart after applying updates
- `$ brew upgrade neovim` Update neovim by your package manager

## usage

```
$ git clone https://github.com/etherswangel/dot_nvim.git ~/.config/nvim
$ nvim
```

Plugins use native `vim.pack` and load eagerly. `lua/plugins.lua` discovers
Lua configuration files directly under `lua/plugins/` in alphabetical order.
Every configuration module returns a list of specs. `lua/plugin_loader.lua` accepts
native `src`, `name` and `version` fields, a local `dir` instead of `src`, and
optional `init`, `setup` and `build` callbacks. The `dependencies` field lists
plugin names that must run first; missing dependencies and cycles are rejected.
`init` runs before plugin scripts load; `setup` runs eagerly after all runtime
paths are available; `build` runs after managed installation or updates.
`nvim-pack-lock.json` records exact revisions and should stay in version control.
Plugin updates rebuild Treesitter parsers and register Molten's remote plugins
when those plugins change. Parser installation does not run on ordinary startup.
The local `dev/multiplexer.nvim` and `dev/sessions.nvim` checkouts are loaded
directly from `runtimepath`.

Nested launches with `$NVIM` load Flatten and open files in a parent tab. Launches
with `$MULTIPLEXER` load only the local multiplexer. Normal launches load the full
collection. `$NVIM` takes precedence when both variables are present.

## sessions

Session management lives in the small local `dev/sessions.nvim` module.
`:SaveSession` writes `.cache/session.vim` in the current working directory using
native `:mksession!`. Hidden unmodified listed buffers are removed first; hidden
modified buffers remain and produce a warning. Saving is manual.

An empty normal launch restores the startup directory's session after plugin
setup. Explicit file arguments, stdin content, another displayed buffer, or an
already loaded session prevent restoration. Existing Mini Sessions session files
remain compatible.

## startup profiling

`:StartupTime` averages 20 launches. `:StartupTime --tries 1` runs a single launch;
`:StartupTime --input-file /path/to/startup.log` displays an existing native log.
The profiler arguments configured in `lua/plugins/ui.lua` clear `$NVIM` and
`$MULTIPLEXER` before each child's configuration loads, so profiling measures the
full editor with the same Neovim executable.

For repeatable terminal measurements with two warmup launches and retained logs:

```sh
python3 scripts/benchmark.py vim-pack . --output /tmp/nvim-startup-comparison \
  --scenarios empty sample.lua sample.py sample.md session
```

Run the same command with another label and a saved configuration directory to
compare configurations at identical plugin revisions. Each scenario records 20
measured launches, a summary, and raw logs. Installation and builds should finish
before profiling. The harness uses temporary fixtures and isolates cache/state,
but uses your installed plugin and provider data. It requires a Unix PTY.

Results from this migration are in [benchmarks/startup.md](benchmarks/startup.md).
Startup timings end at the first screen update and do not measure asynchronous
LSP or Copilot readiness.

## validation

```sh
nvim --headless -u NONE -i NONE -l tests/sessions.lua
nvim --headless -u NONE -i NONE -l tests/pack.lua
```

The package test installs and updates two temporary local Git fixtures; it does
not fetch or update your real plugins. It also checks directory discovery,
symlinked specs and dependency ordering.

To check the full installed configuration, run from a directory without a saved
session:

```sh
nvim --headless -i NONE -c 'luafile /absolute/path/to/nvim/tests/startup.lua'
```

This checks package activation, cursorword underlines after colorscheme reloads,
shell Treesitter highlighting and plugin commands. It uses installed plugins and
parsers.

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
