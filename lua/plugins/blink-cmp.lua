local utils = require('utils')

-- workaround for nvim 0.11 auto setting <Tab> and <S-Tab> mappings
if vim.fn.has('nvim-0.11') == 1 then
  local expand = vim.snippet.expand
  ---@diagnostic disable-next-line:duplicate-set-field
  function vim.snippet.expand(...)
    local tab_map = {
      i = vim.fn.maparg('<Tab>', 'i', false, true),
      s = vim.fn.maparg('<Tab>', 's', false, true),
    }
    local stab_map = {
      i = vim.fn.maparg('<S-Tab>', 'i', false, true),
      s = vim.fn.maparg('<S-Tab>', 's', false, true),
    }

    expand(...)

    vim.schedule(function()
      vim.fn.mapset('i', false, tab_map.i)
      vim.fn.mapset('s', false, tab_map.s)
      vim.fn.mapset('i', false, stab_map.i)
      vim.fn.mapset('s', false, stab_map.s)
    end)
  end
end

return {
  'saghen/blink.cmp',
  version = '*',
  dependencies = {
    'rafamadriz/friendly-snippets',
    { 'saghen/blink.compat', version = '*', lazy = true, opts = {} }
  },

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
      accept = {
        auto_brackets = {
          semantic_token_resolution = { enabled = true }
        }
      },
      menu = { draw = { treesitter = { 'lsp' } } }
    },

    sources = {
      default = function(_ctx)
        local success, node = pcall(vim.treesitter.get_node)
        if success and node and vim.tbl_contains({ 'comment', 'line_comment', 'block_comment' }, node:type()) then
          return { 'buffer' }
        end
        local sources = { 'lsp', 'path', 'snippets', 'buffer' }
        if utils.has_plugin('render-markdown.nvim') then
          table.insert(sources, 'markdown')
        end
        return sources
      end,
      providers = {
        markdown = {
          name = 'RenderMarkdown',
          module = 'render-markdown.integ.blink',
          fallbacks = { 'lsp' },
        }
      }
    },

    keymap = {
      preset = 'none',
      ['<C-Space>'] = { 'show', 'show_documentation', 'hide_documentation' },
      ['<C-e>'] = { function(cmp)
        cmp.hide()
        if utils.has_plugin('copilot.lua') then
          vim.b.copilot_suggestion_hidden = false
          vim.defer_fn(function()
            local suggestion = require('copilot.suggestion')
            if not suggestion.is_visible() then
              suggestion.next()
            end
          end, 100)
        end
      end, 'fallback' },
      ['<CR>'] = { 'accept', 'fallback' },
      ['<S-CR>'] = { function(cmp)
        if not cmp.is_visible() then return end
        local completion_list = require('blink.cmp.completion.list')
        local item = completion_list.get_selected_item()
        if item == nil then return end
        vim.schedule(function() completion_list.apply_preview(item) end)
        return true
      end, 'fallback' },

      ['<Tab>'] = { 'select_next', 'snippet_forward', 'fallback' },
      ['<S-Tab>'] = { 'select_prev', 'snippet_backward', 'fallback' },

      ['<C-b>'] = { 'scroll_documentation_up', 'fallback' },
      ['<C-f>'] = { 'scroll_documentation_down', 'fallback' },
    }
  },
  opts_extend = { 'sources.default' }
}
