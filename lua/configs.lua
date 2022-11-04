local config = {}
map = vim.api.nvim_set_keymap
default = { noremap = false, silent = true }
noremap = { noremap = true, silent = true }
norexpr = { noremap = true, silent = true, expr = true }


function config.copilot()
  map('i', '<m-cr>', [[copilot#Accept("\<cr>")]], norexpr)
  vim.g.copilot_no_tab_map = true
end

function config.lspconfig()
  vim.cmd([[packadd lsp_signature.nvim]])
  vim.cmd([[packadd cmp-nvim-lsp]])
  vim.cmd([[packadd nvim-navic]])

  local opts = { noremap = true, silent = true }
  vim.keymap.set('n', '<leader>d', vim.diagnostic.open_float, opts)
  vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, opts)
  vim.keymap.set('n', ']d', vim.diagnostic.goto_next, opts)
  -- vim.keymap.set('n', '<space>q', vim.diagnostic.setloclist, opts)

  -- If Telescope is installed, use it for LSP code actions
  local builtin = require('telescope.builtin')
  vim.keymap.set('n', '<leader>d', builtin.diagnostics, opts)

  local on_attach = function(client, bufnr)
    -- Enable completion triggered by <c-x><c-o>
    vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')

    local bufopts = { noremap = true, silent = true, buffer = bufnr }
    vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, bufopts)
    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, bufopts)
    vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, bufopts)
    vim.keymap.set('n', 'gr', vim.lsp.buf.references, bufopts)
    vim.keymap.set('n', 'K', vim.lsp.buf.hover, bufopts)
    vim.keymap.set('n', '<c-k>', vim.lsp.buf.signature_help, bufopts)
    -- vim.keymap.set('n', '<space>wa', vim.lsp.buf.add_workspace_folder, bufopts)
    -- vim.keymap.set('n', '<space>wr', vim.lsp.buf.remove_workspace_folder, bufopts)
    -- vim.keymap.set('n', '<space>wl', function()
    --   print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
    -- end, bufopts)
    vim.keymap.set('n', '<leader>D', vim.lsp.buf.type_definition, bufopts)
    vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, bufopts)
    vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, bufopts)
    vim.keymap.set('n', '<leader>f', vim.lsp.buf.format, bufopts)

    -- If Telescope is installed, use it for LSP code actions
    vim.keymap.set('n', 'gd', builtin.lsp_definitions, bufopts)
    vim.keymap.set('n', 'gi', builtin.lsp_implementations, bufopts)
    vim.keymap.set('n', 'gr', builtin.lsp_references, bufopts)
    vim.keymap.set('n', '<leader>D', builtin.lsp_type_definitions, bufopts)

    require "lsp_signature".on_attach({}, bufnr)
    require "nvim-navic".attach(client, bufnr)
  end

  local switch_source_header_splitcmd = function(bufnr, splitcmd)
    bufnr = require('lspconfig').util.validate_bufnr(bufnr)
    local clangd_client = require('lspconfig').util.get_active_client_by_name(bufnr, "clangd")
    local params = { uri = vim.uri_from_bufnr(bufnr) }
    if clangd_client then
      clangd_client.request("textDocument/switchSourceHeader", params, function(err, result)
        if err then
          error(tostring(err))
        end
        if not result then
          vim.notify("Corresponding file can’t be determined", vim.log.levels.ERROR, { title = "LSP Error!" })
          return
        end
        vim.api.nvim_command(splitcmd .. " " .. vim.uri_to_fname(result))
      end)
    else
      vim.notify(
        "Method textDocument/switchSourceHeader is not supported by any active server on this buffer",
        vim.log.levels.ERROR,
        { title = "LSP Error!" }
      )
    end
  end

  local lsp_flags = {
    debounce_text_changes = 150,
  }

  local runtime_path = vim.split(package.path, ";")
  table.insert(runtime_path, "lua/?.lua")
  table.insert(runtime_path, "lua/?/init.lua")

  local capabilities = vim.lsp.protocol.make_client_capabilities()
  capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)

  require('lspconfig')['pyright'].setup {
    on_attach = on_attach,
    flags = lsp_flags,
    capabilities = capabilities,
  }

  require('lspconfig')['gopls'].setup {
    on_attach = on_attach,
    flags = lsp_flags,
    capabilities = capabilities,
  }

  require('lspconfig')['sumneko_lua'].setup {
    on_attach = on_attach,
    flags = lsp_flags,
    capabilities = capabilities,
    settings = {
      Lua = {
        runtime = {
          version = "LuaJIT",
          path = runtime_path,
        },
        diagnostics = {
          globals = { "vim" },
        },
        workspace = {
          library = vim.api.nvim_get_runtime_file("", true),
        },
        telemetry = {
          enable = false,
        },
      },
    },
  }

  require('lspconfig')['rust_analyzer'].setup {
    on_attach = on_attach,
    flags = lsp_flags,
    capabilities = capabilities,
    settings = {
      ["rust-analyzer"] = {}
    }
  }

  capabilities.offsetEncoding = { "utf-16" }
  require('lspconfig')['clangd'].setup {
    on_attach = on_attach,
    flags = lsp_flags,
    capabilities = capabilities,
    single_file_support = true,
    cmd = {
      "clangd",
      "--background-index",
      "--pch-storage=memory",
      "--clang-tidy",
      "--all-scopes-completion",
      "--cross-file-rename",
      "--completion-style=detailed",
    },
    commands = {
      ClangdSwitchSourceHeader = {
        function()
          switch_source_header_splitcmd(0, "edit")
        end,
        description = "Open source/header in current buffer",
      },
      ClangdSwitchSourceHeaderVSplit = {
        function()
          switch_source_header_splitcmd(0, "vsplit")
        end,
        description = "Open source/header in a new vsplit",
      },
      ClangdSwitchSourceHeaderSplit = {
        function()
          switch_source_header_splitcmd(0, "split")
        end,
        description = "Open source/header in a new split",
      },
    },
  }

end

function config.cmp()
  -- luasnip setup
  local luasnip = require 'luasnip'

  -- nvim-cmp setup
  local cmp = require 'cmp'
  cmp.setup {
    snippet = {
      expand = function(args)
        luasnip.lsp_expand(args.body)
      end,
    },
    mapping = cmp.mapping.preset.insert({
      ['<c-d>'] = cmp.mapping.scroll_docs(-4),
      ['<c-f>'] = cmp.mapping.scroll_docs(4),
      ['<c-space>'] = cmp.mapping.complete({}),
      ['<cr>'] = cmp.mapping.confirm {
        behavior = cmp.ConfirmBehavior.Replace,
        select = true,
      },
      ['<tab>'] = cmp.mapping(function(fallback)
        if cmp.visible() then
          cmp.select_next_item()
        elseif luasnip.expand_or_jumpable() then
          luasnip.expand_or_jump()
        else
          fallback()
        end
      end, { 'i', 's' }),
      ['<s-tab>'] = cmp.mapping(function(fallback)
        if cmp.visible() then
          cmp.select_prev_item()
        elseif luasnip.jumpable(-1) then
          luasnip.jump(-1)
        else
          fallback()
        end
      end, { 'i', 's' }),
    }),
    sources = cmp.config.sources({
      { name = 'nvim_lsp' },
      { name = 'nvim_lua' },
      { name = 'luasnip' },
    }, {
      { name = 'buffer' },
      { name = "path" },
      { name = "spell" },
    })
  }

  -- Use buffer source for `/` and `?` (if you enabled `native_menu`, this won't work anymore).
  cmp.setup.cmdline({ '/', '?' }, {
    mapping = cmp.mapping.preset.cmdline(),
    sources = {
      { name = 'buffer' }
    }
  })

  -- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
  cmp.setup.cmdline(':', {
    mapping = cmp.mapping.preset.cmdline(),
    sources = cmp.config.sources({
      { name = 'path' }
    }, {
      { name = 'cmdline' }
    })
  })
end

function config.mason()
  require("mason").setup()
end

function config.mason_lspconfig()
  require("mason-lspconfig").setup()
end

function config.mason_install()
  require('mason-tool-installer').setup {
    ensure_installed = {
      'clangd',
      'clang-format',
      'cpplint',
      'cmake-language-server',
      'cmakelang',
      'cspell',
      'lua-language-server',
    },

    auto_update = false,

    run_on_start = true,
  }
end

function config.lsp_signature()
  require "lsp_signature".setup({
    bind = true, -- This is mandatory, otherwise border config won't get registered.
    hint_enable = true,
    floating_window = true,
    handler_opts = {
      border = "rounded"
    }
  })
end

function config.luasnip()
  require("luasnip").config.set_config({
    history = true,
    updateevents = "TextChanged,TextChangedI",
    delete_check_events = "TextChanged,InsertLeave",
  })
  require("luasnip.loaders.from_lua").lazy_load()
  require("luasnip.loaders.from_vscode").lazy_load()
  require("luasnip.loaders.from_snipmate").lazy_load()
end

function config.dap()
  local dap = require('dap')
  local t = io.popen('which lldb-vscode')
  if t then
    local lldb_path = string.sub(t:read("*all"), 1, -2)
    -- vim.notify("found dap: " .. lldb_path)
    dap.adapters.lldb = {
      name = "lldb",
      type = "executable",
      command = lldb_path,
    }
  end
  dap.configurations.cpp = {
    {
      name = "Launch",
      type = "lldb",
      request = "launch",
      program = function()
        return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
      end,
      cwd = "${workspaceFolder}",
      stopOnEntry = false,
      args = {},
    },
  }
  map('n', '\\c', [[<cmd>lua require'dap'.continue()<cr>]], noremap)
  map('n', '\\a', [[<cmd>lua require'dap'.step_over()<cr>]], noremap)
  map('n', '\\s', [[<cmd>lua require'dap'.step_into()<cr>]], noremap)
  map('n', '\\d', [[<cmd>lua require'dap'.step_out()<cr>]], noremap)
  map('n', '\\b', [[<cmd>lua require'dap'.toggle_breakpoint()<cr>]], noremap)
end

function config.dap_ui()
  require("dapui").setup({
    icons = { expanded = "▾", collapsed = "▸", current_frame = "▸" },
    mappings = {
      expand = { "<cr>", "<2-leftmouse>" },
      open = "o",
      remove = "d",
      edit = "e",
      repl = "r",
      toggle = "t",
    },
    expand_lines = vim.fn.has("nvim-0.7"),

    layouts = {
      {
        elements = {
          { id = "scopes", size = 0.4 },
          "breakpoints",
          "stacks",
        },
        size = 40, -- 40 columns
        position = "right",
      },
      {
        elements = {
          "repl",
          "watches",
          -- "console",
        },
        size = 12,
        position = "bottom",
      },
    },
    controls = {
      enabled = true,
      element = "repl",
      icons = {
        pause = "",
        play = "",
        step_into = "",
        step_over = "",
        step_out = "",
        step_back = "",
        run_last = "↻",
        terminate = "□",
      },
    },
    floating = {
      max_height = nil, -- These can be integers or a float between 0 and 1.
      max_width = nil, -- Floats will be treated as percentage of your screen.
      border = "rounded", -- Border style. Can be "single", "double" or "rounded"
      mappings = {
        close = { "q", "<esc>" },
      },
    },
    windows = { indent = 1 },
    render = {
      max_type_length = nil, -- Can be integer or nil.
      max_value_lines = 100, -- Can be integer or nil.
    }
  })

  local dap = require("dap")
  local dapui = require("dapui")
  dap.listeners.after.event_initialized["dapui_config"] = function()
    vim.cmd([[Vista!]])
    dapui.open({})
  end
  dap.listeners.after.event_terminated["dapui_config"] = function()
    dapui.close({})
  end
  dap.listeners.after.event_exited["dapui_config"] = function()
    dapui.close({})
  end
end

function config.vim_go()
  vim.g.go_highlight_types = 1
  vim.g.go_highlight_fields = 1
  vim.g.go_highlight_functions = 1
  vim.g.go_highlight_function_calls = 1
  vim.g.go_highlight_operators = 1
  vim.g.go_highlight_extra_types = 1
  vim.g.go_term_mode = ":rightbelow split"
  vim.g.go_term_enabled = 1
  vim.g.go_term_reuse = 1
  vim.g.go_term_width = 50
  vim.g.go_term_height = 10
  vim.g.go_term_close_on_exit = 0
  vim.g.go_list_type = "quickfix"
  vim.g.go_fmt_autosave = 0
end

function config.rust()
  vim.g.rust_recommended_style = 0
  vim.g.rustfmt_autosave = 0
end

function config.telescope()
  local opts = { noremap = true, silent = true }
  local builtin = require('telescope.builtin')
  vim.keymap.set('n', 'ff', builtin.find_files, opts)
  vim.keymap.set('n', 'fg', builtin.live_grep, opts)
  vim.keymap.set('v', 'fg', builtin.grep_string, opts)
  vim.keymap.set('n', 'fb', builtin.buffers, opts)
  vim.keymap.set('n', 'fh', builtin.help_tags, opts)
  local actions = require('telescope.actions')
  require('telescope').setup({
    defaults = {
      mappings = {
        i = {
          ["<esc>"] = actions.close,
          ["<m-k>"] = actions.move_selection_previous,
          ["<m-j>"] = actions.move_selection_next,
        },
      },
    },
    extensions = {
      fzf = {
        fuzzy = true,
        override_generic_sorter = true,
        override_file_sorter = true,
        case_mode = "smart_case",
      },
      ["ui-select"] = {
        require("telescope.themes").get_dropdown {
          -- even more opts
        }
      },
      -- frecency = {
      -- 	show_scores = true,
      -- 	show_unindexed = true,
      -- 	ignore_patterns = { "*.git/*", "*/tmp/*" },
      -- },
    },
  })
  require("telescope").load_extension("fzf")
  require("telescope").load_extension("ui-select")
end

function config.treesitter()
  require('nvim-treesitter.configs').setup {
    -- A list of parser names, or "all"
    ensure_installed = { "c", "cpp", "cmake", "lua", "rust", "go",
      "bash", "comment", "python", "json", "yaml",
      "html", "css", "javascript", "typescript", },

    sync_install = false,
    auto_install = true,

    highlight = {
      enable = true,

      disable = function(lang, buf)
        local max_filesize = 100 * 1024 -- 100 KB
        local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
        if ok and stats and stats.size > max_filesize then
          return true
        end
      end,

      additional_vim_regex_highlighting = false,
    },

    incremental_selection = {
      enable = true,
      keymaps = {
        init_selection = "<cr>",
        node_incremental = "<space>",
        scope_incremental = "<cr>",
        node_decremental = "<bs>",
      },
    },

    indent = {
      enable = true
    },

    rainbow = {
      enable = true,
      extended_mode = true,
      max_file_lines = nil, -- Do not enable for files with more than n lines, int
    },

    autotag = {
      enable = true,
    },

    textobjects = {
      select = {
        enable = true,
        lookahead = true,
        keymaps = {
          ["af"] = "@function.outer",
          ["if"] = "@function.inner",
          ["ac"] = "@class.outer",
          ["ic"] = "@class.inner",
        },
      },
      move = {
        enable = true,
        set_jumps = true, -- whether to set jumps in the jumplist
        goto_next_start = {
          ["]["] = "@function.outer",
          ["]m"] = "@class.outer",
        },
        goto_next_end = {
          ["]]"] = "@function.outer",
          ["]M"] = "@class.outer",
        },
        goto_previous_start = {
          ["[["] = "@function.outer",
          ["[m"] = "@class.outer",
        },
        goto_previous_end = {
          ["[]"] = "@function.outer",
          ["[M"] = "@class.outer",
        },
      },
    },

    matchup = {
      enable = true, -- mandatory, false will disable the whole extension
      disable = {}, -- optional, list of language that will be disabled
    },
  }
end

function config.auto_save()
  require("auto-save").setup({
    enabled = true, -- start auto-save when the plugin is loaded (i.e. when your package manager loads it)
    execution_message = {
      message = function() -- message to print on save
        return ("AutoSave: saved at " .. vim.fn.strftime("%H:%M:%S"))
      end,
      dim = 0.18, -- dim the color of `message`
      cleaning_interval = 1250, -- (milliseconds) automatically clean MsgArea after displaying `message`. See :h MsgArea
    },
    trigger_events = { "InsertLeave", "TextChanged" }, -- vim events that trigger auto-save. See :h events
    -- function that determines whether to save the current buffer or not
    -- return true: if buffer is ok to be sav ed
    -- return false: if it's not ok to be saved
    condition = function(buf)
      local fn = vim.fn
      local utils = require("auto-save.utils.data")

      if fn.getbufvar(buf, "&modifiable") == 1 and
          utils.not_in(fn.getbufvar(buf, "&filetype"), {}) then
        return true -- met condition(s), can save
      end
      return false -- can't save
    end,
    write_all_buffers = false, -- write all buffers when the current one meets `condition`
    debounce_delay = 135, -- saves the file at most every `debounce_delay` milliseconds
    callbacks = { -- functions to be executed at different intervals
      enabling = nil, -- ran when enabling auto-save
      disabling = nil, -- ran when disabling auto-save
      before_asserting_save = nil, -- ran before checking `condition`
      before_saving = nil, -- ran before doing the actual save
      after_saving = nil -- ran after doing the actual save
    }
  })
end

function config.tabout()
  require("tabout").setup({
    tabkey = "<tab>",
    backwards_tabkey = "<s-tab>",
    ignore_beginning = true,
    act_as_tab = true,
    enable_backward = true,
    completion = true,
    tabouts = {
      { open = "'", close = "'" },
      { open = '"', close = '"' },
      { open = "`", close = "`" },
      { open = "(", close = ")" },
      { open = "[", close = "]" },
      { open = "{", close = "}" },
    },
    exclude = {},
  })
end

function config.autopairs()
  require("nvim-autopairs").setup({})

  -- If you want insert `(` after select function or method item
  local cmp_autopairs = require("nvim-autopairs.completion.cmp")
  local cmp = require("cmp")
  local handlers = require("nvim-autopairs.completion.handlers")
  cmp.event:on(
    "confirm_done",
    cmp_autopairs.on_confirm_done({
      filetypes = {
        -- "*" is an alias to all filetypes
        ["*"] = {
          ["("] = {
            kind = {
              cmp.lsp.CompletionItemKind.Function,
              cmp.lsp.CompletionItemKind.Method,
            },
            handler = handlers["*"],
          },
        },
        -- Disable for tex
        tex = false,
      },
    })
  )
end

function config.accelerated_jk()
  map('n', 'j', [[<plug>(accelerated_jk_gj)]], default)
  map('n', 'k', [[<plug>(accelerated_jk_gk)]], default)
end

function config.impatient()
  require('impatient')
end

function config.filetype()
  -- In init.lua or filetype.nvim's config file
  require("filetype").setup({
    overrides = {
      extensions = {
        -- Set the filetype of *.pn files to potion
        pn = "potion",
      },
      literal = {
        -- Set the filetype of files named "MyBackupFile" to lua
        MyBackupFile = "lua",
      },
      complex = {
        -- Set the filetype of any full filename matching the regex to gitconfig
        [".*git/config"] = "gitconfig", -- Included in the plugin
      },

      -- The same as the ones above except the keys map to functions
      function_extensions = {
        ["c"] = function()
          vim.bo.filetype = "c"
        end,
        ["cpp"] = function()
          vim.bo.filetype = "cpp"
          -- Remove annoying indent jumping
          -- vim.bo.cinoptions = vim.bo.cinoptions .. "L0"
        end,
        ["pdf"] = function()
          vim.bo.filetype = "pdf"
          -- Open in PDF viewer (Skim.app) automatically
          vim.fn.jobstart(
            "open -a skim " .. '"' .. vim.fn.expand("%") .. '"'
          )
        end,
      },
      function_literal = {
        Brewfile = function()
          vim.cmd("syntax off")
        end,
      },
      function_complex = {
        ["*.math_notes/%w+"] = function()
          vim.cmd("iabbrev $ $$")
        end,
      },

      shebang = {
        -- Set the filetype of files with a dash shebang to sh
        dash = "sh",
      },
    },
  })
end

function config.sniprun()
  require 'sniprun'.setup({
    display = {
      "Classic", --# display results in the command-line  area
      "VirtualTextOk", --# display ok results as virtual text (multiline is shortened)
      "VirtualTextErr", --# display error results as virtual text
      -- "TempFloatingWindow",      --# display results in a floating window
      -- "LongTempFloatingWindow",  --# same as above, but only long results. To use with VirtualText__
      -- "Terminal",                --# display results in a vertical split
      -- "TerminalWithCode",        --# display results and code history in a vertical split
      "NvimNotify", --# display with the nvim-notify plugin
      -- "Api"                      --# return output to a programming interface
    },

    display_options = {
      terminal_width = 45, --# change the terminal display option width
      notification_timeout = 5 --# timeout for nvim_notify output
    },

    --# possible values are 'none', 'single', 'double', or 'shadow'
    borders = 'single', --# display borders around floating windows
  })
end

function config.comment()
  require('nvim_comment').setup({
    -- Linters prefer comment and line to have a space in between markers
    marker_padding = true,
    -- should comment out empty or whitespace only lines
    comment_empty = false,
    -- trim empty comment whitespace
    comment_empty_trim_whitespace = true,
    -- Should key mappings be created
    create_mappings = true,
    -- Normal mode mapping left hand side
    line_mapping = "gcc",
    -- Visual/Operator mapping left hand side
    operator_mapping = "gc",
    -- text object mapping, comment chunk,,
    comment_chunk_text_object = "ic",
    -- Hook function to call before commenting takes place
    hook = nil
  })
end

function config.toggleterm()
  require("toggleterm").setup {
    shade_terminals = false,
    start_in_insert = true,
    float_opts = {
      border = 'curved',
      width = function(term)
        return math.ceil(vim.o.columns * 0.5)
      end,
      height = 40,
      -- winblend = 3,
    },
  }

  map('n', ';t', [[:ToggleTerm<cr>]], noremap)
  map('t', ';t', [[<c-\><c-n>:ToggleTerm<cr>]], noremap)

  map('n', '<leader>t1', [[:1ToggleTerm direction=horizontal size=15<cr>]], noremap)
  map('n', '<leader>t2', [[:2ToggleTerm direction=horizontal size=15<cr>]], noremap)
  map('n', '<leader>t3', [[:3ToggleTerm direction=horizontal size=15<cr>]], noremap)
  map('n', '<leader>t4', [[:4ToggleTerm direction=horizontal size=15<cr>]], noremap)
  map('n', '<leader>tt', [[:5ToggleTerm direction=float size=15<cr>]], noremap)
end

function config.better_escape()
  require("better_escape").setup {
    mapping = { "jj" }, -- a table with mappings to use
    timeout = vim.o.timeoutlen, -- the time in which the keys must be hit in ms. Use option timeoutlen by default
    clear_empty_lines = false, -- clear line after escaping if there is only whitespace
    keys = "<esc>", -- keys used for escaping, if it is a function will use the result everytime
    -- example(recommended)
    -- keys = function()
    --   return vim.api.nvim_win_get_cursor(0)[2] > 1 and '<esc>l' or '<esc>'
    -- end,
  }
end

function config.specs()
  require('specs').setup {
    show_jumps       = true,
    min_jump         = 20,
    popup            = {
      delay_ms = 0, -- delay before popup displays
      inc_ms = 8, -- time increments used for fade/resize effects
      blend = 10, -- starting blend, between 0-100 (fully transparent), see :h winblend
      width = 30,
      winhl = "PMenu",
      fader = require('specs').linear_fader,
      resizer = require('specs').shrink_resizer
    },
    ignore_filetypes = {},
    ignore_buftypes  = {
      nofile = true,
    },
  }
end

function config.stabilize()
  require("stabilize").setup()
end

function config.neoscroll()
  require('neoscroll').setup({
    -- All these keys will be mapped to their corresponding default scrolling animation
    mappings = { '<C-u>', '<C-d>', '<C-b>', '<C-f>',
      '<C-y>', '<C-e>', 'zt', 'zz', 'zb', '<pageup>', '<pagedown>' },
    hide_cursor = true, -- Hide cursor while scrolling
    stop_eof = true, -- Stop at <EOF> when scrolling downwards
    respect_scrolloff = false, -- Stop scrolling when the cursor reaches the scrolloff margin of the file
    cursor_scrolls_alone = true, -- The cursor will keep on scrolling even if the window cannot scroll further
    easing_function = nil, -- Default easing function
    pre_hook = nil, -- Function to run before the scrolling animation starts
    post_hook = nil, -- Function to run after the scrolling animation ends
    performance_mode = false, -- Disable "Performance Mode" on all buffers.
  })
end

function config.gitsigns()
  require('gitsigns').setup {
    on_attach = function(bufnr)
      local gs = package.loaded.gitsigns

      local function map(mode, l, r, opts)
        opts = opts or {}
        opts.buffer = bufnr
        vim.keymap.set(mode, l, r, opts)
      end

      -- Navigation
      map('n', ']h', function()
        if vim.wo.diff then return ']h' end
        vim.schedule(function() gs.next_hunk() end)
        return '<Ignore>'
      end, { expr = true })

      map('n', '[h', function()
        if vim.wo.diff then return '[h' end
        vim.schedule(function() gs.prev_hunk() end)
        return '<Ignore>'
      end, { expr = true })

      -- Actions
      map({ 'n', 'v' }, '<leader>hs', ':Gitsigns stage_hunk<cr>')
      map({ 'n', 'v' }, '<leader>hr', ':Gitsigns reset_hunk<cr>')
      map('n', '<leader>hS', gs.stage_buffer)
      map('n', '<leader>hu', gs.undo_stage_hunk)
      map('n', '<leader>hR', gs.reset_buffer)
      map('n', '<leader>hp', gs.preview_hunk)
      map('n', '<leader>hb', function() gs.blame_line { full = true } end)
      map('n', '<leader>tb', gs.toggle_current_line_blame)
      map('n', '<leader>hd', gs.diffthis)
      map('n', '<leader>hD', function() gs.diffthis('~') end)
      map('n', '<leader>td', gs.toggle_deleted)

      -- Text object
      map({ 'o', 'x' }, 'ih', ':<c-U>Gitsigns select_hunk<cr>')
    end
  }
end

function config.notify()
  require("notify").setup({
    stages = "fade_in_slide_out",
    timeout = 3000,
    background_colour = "#1e222a",
    icons = {
      ERROR = " ",
      WARN = " ",
      INFO = " ",
      DEBUG = " ",
      TRACE = " ",
    },
  })
  vim.notify = require("notify")
end

function config.alpha()
  require('alpha').setup(require('alpha.themes.dashboard').config)
end

function config.nvim_tree()
  map('n', ';e', [[:NvimTreeFocus<cr>]], noremap)
  require("nvim-tree").setup({
    open_on_setup = true,
    open_on_setup_file = true,
    sort_by = "case_sensitive",
    view = {
      adaptive_size = true,
      mappings = {
        list = {
          { key = "h", action = "dir_up" },
          { key = "cd", action = "cd" },
          { key = "N", action = "create" },
          { key = "DD", action = "remove" },
          { key = "dd", action = "trash" },
          { key = "rr", action = "rename" },
          { key = "r", action = "" },
        },
      },
    },
    renderer = {
      group_empty = true,
    },
    filters = {
      dotfiles = true,
    },
  })
end

function config.vista()
  map('n', ';s', [[:Vista!!<cr>]], noremap)

  vim.g.vista_icon_indent = { "╰─▸ ", "├─▸ " }
  vim.g.vista_default_executive = 'ctags'
  vim.g.vista_executive_for = {
    py = 'nvim_lsp',
    go = 'nvim_lsp',
    cpp = 'nvim_lsp',
    lua = 'nvim_lsp',
  }
  vim.g.vista_ctags_cmd = {
    haskell = 'hasktags -x -o - -c',
  }
  vim.g.vista_fzf_preview = { 'right:50%' }
  vim.g['vista#renderer#enable_icon'] = 1
  vim.g['vista#renderer#icons']['function'] = [[\]]
  vim.g['vista#renderer#icons']['variable'] = [[\]]
end

function config.fidget()
  require("fidget").setup {
    window = { blend = 0 },
  }
end

function config.indent_blankline()
  require("indent_blankline").setup {
    show_current_context = true,
    show_current_context_start = true,
    filetype_exclude = {
      "startify",
      "dashboard",
      "dotooagenda",
      "log",
      "fugitive",
      "gitcommit",
      "packer",
      "vimwiki",
      "markdown",
      "json",
      "txt",
      "vista",
      "help",
      "todoist",
      "NvimTree",
      "peekaboo",
      "git",
      "TelescopePrompt",
      "undotree",
      "flutterToolsOutline",
      "", -- for all buffers without a file type
    },
    buftype_exclude = { "terminal", "nofile" },
  }
  vim.cmd("autocmd CursorMoved * IndentBlanklineRefresh")
end

function config.theme()
  vim.cmd [[colorscheme nord]]
  vim.cmd [[hi Normal guibg=NONE ctermbg=NONE]]
  vim.cmd [[hi NonText guibg=NONE ctermbg=NONE]]
  vim.cmd [[hi SignColumn guibg=NONE ctermbg=NONE]]
end

function config.galaxyline()
  local gl = require('galaxyline')
  local navic = require('nvim-navic')
  local gls = gl.section
  local extension = require('galaxyline.provider_extensions')

  gl.short_line_list = {
    'LuaTree',
    'NvimTree',
    'vista',
    'dbui',
    'startify',
    'term',
    'nerdtree',
    'fugitive',
    'fugitiveblame',
    'plug',
    'plugins'
  }

  VistaPlugin = extension.vista_nearest

  local colors = {
    bg = "#282c34",
    line_bg = "#353644",
    fg = '#8FBCBB',
    fg_green = '#65a380',

    yellow = '#fabd2f',
    cyan = '#008080',
    darkblue = '#081633',
    green = '#afd700',
    orange = '#FF8800',
    purple = '#5d4d7a',
    magenta = '#c678dd',
    blue = '#51afef';
    red = '#ec5f67'
  }

  local function file_readonly()
    if vim.bo.filetype == 'help' then
      return ''
    end
    local icon = ''
    if vim.bo.readonly == true then
      return ' ' .. icon .. '  '
    end
    return ''
  end

  local function get_current_file_name()
    -- local file = vim.fn.expand('%:t')
    local file = vim.fn.expand('%:f')
    if vim.fn.empty(file) == 1 then return '' end
    if string.len(file_readonly()) ~= 0 then
      return file .. file_readonly()
    end
    local icon = ''
    if vim.bo.modifiable then
      if vim.bo.modified then
        return file .. ' ' .. icon .. '  '
      end
    end
    return file .. '  '
  end

  local function has_file_type()
    local f_type = vim.bo.filetype
    if not f_type or f_type == '' then
      return false
    end
    return true
  end

  local function buffer_not_empty()
    if vim.fn.empty(vim.fn.expand('%:t')) ~= 1 then
      return true
    end
    return false
  end

  gls.left[1] = {
    FirstElement = {
      provider = function() return ' ' end,
      highlight = { colors.blue, colors.line_bg }
    },
  }

  gls.left[2] = {
    ViMode = {
      provider = function()
        -- auto change color() according the vim mode
        local alias = {
          n      = 'NORMAL',
          i      = 'INSERT',
          c      = 'COMMAND',
          cv     = 'COMMAND-LINE',
          v      = 'VISUAL',
          V      = 'VISUAL',
          ['']  = 'VISUAL',
          r      = 'HIT-ENTER',
          rm     = '--MORE',
          ['r?'] = ':CONFIRM',
          R      = 'REPLACE',
          Rv     = 'VIRTUAL',
          s      = 'SELECT',
          S      = 'SELECT',
          ['']  = 'SELECT',
          t      = 'TERMINAL',
          ['!']  = 'SHELL',
        }
        local mode_color = {
          n = colors.green,
          i = colors.blue,
          c = colors.purple,
          cv = colors.red,
          ce = colors.red,
          v = colors.magenta,
          V = colors.blue,
          [''] = colors.blue,
          r = colors.cyan,
          rm = colors.cyan,
          ['r?'] = colors.cyan,
          R = colors.purple,
          Rv = colors.purple,
          s = colors.orange,
          S = colors.orange,
          [''] = colors.orange,
          t = colors.green,
          ['!'] = colors.green,
          no = colors.magenta,
          ic = colors.yellow,
        }
        local vim_mode = vim.fn.mode()
        vim.api.nvim_command('hi GalaxyViMode guifg=' .. mode_color[vim_mode])
        return alias[vim_mode] .. '   '
      end,
      highlight = { colors.red, colors.line_bg, 'bold' },
    },
  }

  gls.left[3] = {
    FileIcon = {
      provider = 'FileIcon',
      condition = buffer_not_empty,
      highlight = { require('galaxyline.provider_fileinfo').get_file_icon_color, colors.line_bg },
    },
  }

  gls.left[4] = {
    FileName = {
      provider = { get_current_file_name, 'FileSize' },
      condition = buffer_not_empty,
      highlight = { colors.fg, colors.line_bg, 'bold' }
    }
  }

  gls.left[5] = {
    GitIcon = {
      provider = function() return '  ' end,
      condition = require('galaxyline.provider_vcs').check_git_workspace,
      highlight = { colors.yellow, colors.line_bg },
    }
  }

  gls.left[6] = {
    GitBranch = {
      provider = 'GitBranch',
      condition = require('galaxyline.provider_vcs').check_git_workspace,
      highlight = { colors.yellow, colors.line_bg, 'bold' },
    }
  }

  local checkwidth = function()
    local squeeze_width = vim.fn.winwidth(0) / 2
    if squeeze_width > 40 then
      return true
    end
    return false
  end

  gls.left[7] = {
    DiffAdd = {
      provider = 'DiffAdd',
      condition = checkwidth,
      icon = '   ',
      highlight = { colors.green, colors.line_bg },
    }
  }

  gls.left[8] = {
    DiffModified = {
      provider = 'DiffModified',
      condition = checkwidth,
      icon = '   ',
      highlight = { colors.orange, colors.line_bg },
    }
  }

  gls.left[9] = {
    DiffRemove = {
      provider = 'DiffRemove',
      condition = checkwidth,
      icon = '   ',
      highlight = { colors.red, colors.line_bg },
    }
  }

  gls.left[10] = {
    Space = {
      provider = function() return ' ' end,
      separator = '',
      separator_highlight = { colors.bg, colors.line_bg },
      highlight = { colors.line_bg, colors.line_bg }
    }
  }

  gls.left[11] = {
    DiagnosticError = {
      provider = 'DiagnosticError',
      icon = '  ',
      highlight = { colors.red, colors.bg }
    }
  }

  gls.left[13] = {
    DiagnosticWarn = {
      provider = 'DiagnosticWarn',
      icon = '  ',
      highlight = { colors.yellow, colors.bg },
    }
  }

  gls.left[14] = {
    nvimGPS = {
      provider = function()
        return navic.get_location()
      end,
      condition = function()
        return navic.is_available()
      end,
      icon = '  ',
      highlight = { colors.yellow, colors.bg },
    }
  }

  gls.right[1] = {
    FileFormat = {
      provider = 'FileFormat',
      separator = ' ',
      separator_highlight = { colors.bg, colors.line_bg },
      highlight = { colors.fg, colors.line_bg, 'bold' },
    }
  }
  gls.right[2] = {
    Vista = {
      provider = VistaPlugin,
      separator = ' ',
      separator_highlight = { colors.bg, colors.line_bg },
      highlight = { colors.fg, colors.line_bg, 'bold' },
    }
  }
  gls.right[3] = {
    LineInfo = {
      provider = 'LineColumn',
      separator = ' | ',
      separator_highlight = { colors.blue, colors.line_bg },
      highlight = { colors.fg, colors.line_bg },
    },
  }
  gls.right[4] = {
    PerCent = {
      provider = 'LinePercent',
      separator = ' ',
      separator_highlight = { colors.line_bg, colors.line_bg },
      highlight = { colors.cyan, colors.darkblue, 'bold' },
    }
  }

  -- gls.right[5] = {
  --   ScrollBar = {
  --     provider = 'ScrollBar',
  --     highlight = {colors.blue,colors.purple},
  --   }
  -- }

  gls.short_line_left[1] = {
    BufferType = {
      provider = 'FileTypeName',
      separator = '',
      condition = has_file_type,
      separator_highlight = { colors.purple, colors.bg },
      highlight = { colors.fg, colors.purple }
    }
  }


  gls.short_line_right[1] = {
    BufferIcon = {
      provider = 'BufferIcon',
      separator = '',
      condition = has_file_type,
      separator_highlight = { colors.purple, colors.bg },
      highlight = { colors.fg, colors.purple }
    }
  }
end

function config.bufferline()
  map('n', '<tab>', [[:BufferLineCycleNext<cr>]], noremap)
  map('n', '<s-tab>', [[:BufferLineCyclePrev<cr>]], noremap)

  map('n', ']b', [[:BufferLineMoveNext<cr>]], noremap)
  map('n', '[b', [[:BufferLineMovePrev<cr>]], noremap)

  map('n', '<m-1>', [[<cmd>BufferLineGoToBuffer 1<cr>]], noremap)
  map('n', '<m-2>', [[<cmd>BufferLineGoToBuffer 2<cr>]], noremap)
  map('n', '<m-3>', [[<cmd>BufferLineGoToBuffer 3<cr>]], noremap)
  map('n', '<m-4>', [[<cmd>BufferLineGoToBuffer 4<cr>]], noremap)
  map('n', '<m-5>', [[<cmd>BufferLineGoToBuffer 5<cr>]], noremap)
  map('n', '<m-6>', [[<cmd>BufferLineGoToBuffer 6<cr>]], noremap)
  map('n', '<m-7>', [[<cmd>BufferLineGoToBuffer 7<cr>]], noremap)
  map('n', '<m-8>', [[<cmd>BufferLineGoToBuffer 8<cr>]], noremap)
  map('n', '<m-9>', [[<cmd>BufferLineGoToBuffer 9<cr>]], noremap)

  vim.opt.termguicolors = true

  local nord0 = "#2E3440"
  local nord9 = "#81A1C1"
  local fill = nord0 --'#181c24' if separator_style is "slant"
  local indicator = nord9

  require('bufferline').setup {
    highlights = {
      buffer_visible = {
        italic = true
      },

      numbers_visible = {
        italic = true
      },

      diagnostic_selected = {
        bold = true,
        italic = true,
      },

      hint_selected = {
        bold = true,
        italic = true,
      },
      hint_diagnostic_selected = {
        bold = true,
        italic = true,
      },

      info_selected = {
        bold = true,
        italic = true,
      },
      info_diagnostic_selected = {
        bold = true,
        italic = true,
      },

      warning_selected = {
        bold = true,
        italic = true,
      },
      warning_diagnostic_selected = {
        bold = true,
        italic = true,
      },
      error_selected = {
        bold = true,
        italic = true,
      },
      error_diagnostic_selected = {
        bold = true,
        italic = true,
      },

      separator = {
        fg = fill,
      },
      separator_selected = {
        fg = fill,
      },
      separator_visible = {
        fg = fill,
      },
      indicator_selected = {
        fg = indicator,
      },
      pick = {
        bold = true,
        italic = true,
      },
      pick_selected = {
        bold = true,
        italic = true,
      },
      pick_visible = {
        bold = true,
        italic = true,
      },
    },
    options = {
      mode = "buffers", -- set to "tabs" to only show tabpages instead
      numbers = "ordinal", -- | "ordinal" | "buffer_id" | "both" | function({ ordinal, id, lower, raise }): string,
      --- @deprecated, please specify numbers as a function to customize the styling
      -- number_style = "superscript", --| "subscript" | "" | { "none", "subscript" }, -- buffer_id at index 1, ordinal at index 2
      close_command = "bdelete! %d", -- can be a string | function, see "Mouse actions"
      right_mouse_command = "bdelete! %d", -- can be a string | function, see "Mouse actions"
      left_mouse_command = "buffer %d", -- can be a string | function, see "Mouse actions"
      middle_mouse_command = nil, -- can be a string | function, see "Mouse actions"
      -- NOTE: this plugin is designed with this icon in mind,
      -- and so changing this is NOT recommended, this is intended
      -- as an escape hatch for people who cannot bear it for whatever reason
      indicator = {
        icon = '▎',
        style = 'underline'
      },
      buffer_close_icon = '',
      modified_icon = '●',
      close_icon = '',
      left_trunc_marker = '',
      right_trunc_marker = '',
      --- name_formatter can be used to change the buffer's label in the bufferline.
      --- Please note some names can/will break the
      --- bufferline so use this at your discretion knowing that it has
      --- some limitations that will *NOT* be fixed.
      name_formatter = function(buf) -- buf contains a "name", "path" and "bufnr"
        -- remove extension from markdown files for example
        if buf.name:match('%.md') then
          return vim.fn.fnamemodify(buf.name, ':t:r')
        end
      end,
      max_name_length = 18,
      max_prefix_length = 15, -- prefix used when a buffer is de-duplicated
      tab_size = 18,
      diagnostics = "nvim_lsp", --false | "nvim_lsp" | "coc",
      diagnostics_update_in_insert = true,
      diagnostics_indicator = function(count, level, diagnostics_dict, context)
        return "(" .. count .. ")"
      end,
      -- NOTE: this will be called a lot so don't do any heavy processing here
      custom_filter = function(buf_number, buf_numbers)
        -- filter out filetypes you don't want to see
        -- if vim.bo[buf_number].filetype ~= "<i-dont-want-to-see-this>" then
        --   return true
        -- end
        -- filter out by buffer name
        if vim.fn.bufname(buf_number) ~= "[dap-repl]" then
          return true
        end
        -- filter out based on arbitrary rules
        -- e.g. filter out vim wiki buffer from tabline in your work repo
        if vim.fn.getcwd() == "<work-repo>" and vim.bo[buf_number].filetype ~= "wiki" then
          return true
        end
        -- filter out by it's index number in list (don't show first buffer)
        if buf_numbers[1] ~= buf_number then
          return true
        end
      end,
      offsets = { { filetype = "NvimTree", text = "File Explorer", highlight = "Directory", text_align = "center" } }, -- | function , text_align = "left" | "center" | "right"}},
      color_icons = true,
      show_buffer_icons = true, --| false, -- disable filetype icons for buffers
      show_buffer_close_icons = true, --| false,
      show_close_icon = false, --| false,
      show_tab_indicators = false, -- | false,
      persist_buffer_sort = true, -- whether or not custom sorted buffers should persist
      -- can also be a table containing 2 custom separators
      -- [focused and unfocused]. eg: { '|', '|' }
      separator_style = "{'', ''}", --| "slant" | "thick" | "thin" | { 'any', 'any' },
      enforce_regular_tabs = false, --| true,
      always_show_bufferline = true, -- | false,
      hover = {
        enabled = false,
        delay = 200,
        reveal = { 'close' }
      },
      sort_by = 'directory', -- ,'id' | 'extension' | 'relative_directory' | 'directory' | 'tabs' | function(buffer_a, buffer_b)
      --   -- add custom logic
      --   return buffer_a.modified > buffer_b.modified
      -- end
      groups = {
        options = {
          toggle_hidden_on_enter = true -- when you re-enter a hidden group this options re-opens that group so the buffer is visible
        },
        items = {
          {
            name = "Tests", -- Mandatory
            highlight = { undercurl = true, sp = "blue" }, -- Optional
            priority = 2, -- determines where it will appear relative to other groups (Optional)
            icon = "", -- Optional
            matcher = function(buf) -- Mandatory
              return buf.name:match('%_test') or buf.name:match('%_spec')
            end,
          },
          {
            name = "Docs",
            highlight = { sp = "green" },
            auto_close = false, -- whether or not close this group if it doesn't contain the current buffer
            matcher = function(buf)
              return buf.name:match('%.md')
            end,
            separator = { -- Optional
              style = require('bufferline.groups').separator.tab },
          },
          {
            name = "Hdrs",
            highlight = { sp = "green" },
            auto_close = false, -- whether or not close this group if it doesn't contain the current buffer
            matcher = function(buf)
              return buf.name:match('%.hpp') or buf.name:match('%.hh') or buf.name:match('%.h')
            end,
            separator = { -- Optional
              style = require('bufferline.groups').separator.tab },
          },
          {
            name = "Srcs",
            -- highlight = { fg = fill, bg = bg },
            auto_close = false, -- whether or not close this group if it doesn't contain the current buffer
            matcher = function(buf)
              return buf.name:match('%.cpp') or buf.name:match('%.cc') or buf.name:match('%.c')
            end,
            separator = { -- Optional
              style = require('bufferline.groups').separator.tab },
          },
          {
            name = "Pkgs",
            highlight = { sp = "green" },
            auto_close = false, -- whether or not close this group if it doesn't contain the current buffer
            matcher = function(buf)
              return buf.name:match('CMakeLists.txt') or buf.name:match('package.xml')
            end,
            separator = { -- Optional
              style = require('bufferline.groups').separator.tab },
          },
        }
      },
    }
  }
end

return config
