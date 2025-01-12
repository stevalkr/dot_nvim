local utils = require('utils')

return {
  'saghen/blink.cmp',
  version = '*',
  dependencies = {
    'rafamadriz/friendly-snippets',
    { 'saghen/blink.compat', version = '*', lazy = true, opts = {} }
  },

  ---@module 'blink.cmp'
  ---@type blink.cmp.Config
  opts = {
    appearance = {
      nerd_font_variant = 'mono'
    },

    completion = {
      ghost_text = { enabled = true },
      list = {
        selection = {
          preselect = false,
          auto_insert = function(ctx)
            return ctx.mode == 'cmdline'
          end
        }
      },
      documentation = {
        auto_show = true,
        auto_show_delay_ms = 500
      },
      menu = { draw = { treesitter = { 'lsp' } } }
    },

    sources = {
      default = function(_ctx)
        local success, node = pcall(vim.treesitter.get_node)
        if success and node and vim.tbl_contains({ 'comment', 'line_comment', 'block_comment' }, node:type()) then
          return { 'buffer' }
        end
        local sources = { 'lsp', 'path', 'snippets', 'buffer', 'markdown' }
        if utils.has_plugin('avante.nvim') then
          table.insert(sources, 'avante_commands')
          table.insert(sources, 'avante_mentions')
          table.insert(sources, 'avante_files')
        end
        return sources
      end,
      providers = {
        markdown = {
          name = 'RenderMarkdown',
          module = 'render-markdown.integ.blink',
          fallbacks = { 'lsp' },
        },
        avante_commands = {
          name = 'avante_commands',
          module = 'blink.compat.source',
          score_offset = 90,
          opts = {},
        },
        avante_files = {
          name = 'avante_commands',
          module = 'blink.compat.source',
          score_offset = 100,
          opts = {},
        },
        avante_mentions = {
          name = 'avante_mentions',
          module = 'blink.compat.source',
          score_offset = 1000,
          opts = {},
        }
      },
    },

    keymap = {
      preset = 'none',
      ['<C-space>'] = { 'show', 'show_documentation', 'hide_documentation' },
      ['<C-e>'] = { 'hide', 'fallback' },
      ['<CR>'] = { 'accept', 'fallback' },

      ['<Tab>'] = { 'select_next', 'snippet_forward', 'fallback' },
      ['<S-Tab>'] = { 'select_prev', 'snippet_backward', 'fallback' },

      ['<C-b>'] = { 'scroll_documentation_up', 'fallback' },
      ['<C-f>'] = { 'scroll_documentation_down', 'fallback' },
    }
  },
  opts_extend = { 'sources.default' }
}
