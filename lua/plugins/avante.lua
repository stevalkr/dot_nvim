local utils = require('utils')
return {

  'yetone/avante.nvim',
  cmd = { 'AvanteAsk', 'AvanteToggle', 'AvanteChat' },
  keys = {
    { '<leader>aa', '<Cmd>AvanteToggle<CR>', desc = 'Toggle Avante' }
  },
  version = false,
  opts = {
    -- provider = 'copilot',
    provider = "openrouter_claude",
    vendors = {
      openrouter_claude = {
        __inherited_from = 'openai',
        endpoint = 'https://openrouter.ai/api/v1',
        api_key_name = { 'op', 'read', 'op://Private/OpenRouter/credential' },
        model = 'anthropic/claude-3.7-sonnet:thinking',
      },
      openrouter_gemini = {
        __inherited_from = 'openai',
        endpoint = 'https://openrouter.ai/api/v1',
        api_key_name = { 'op', 'read', 'op://Private/OpenRouter/credential' },
        model = 'google/gemini-2.5-pro-exp-03-25:free',
      },
    },
    dual_boost = {
      enabled = true,
      first_provider = "openrouter_gemini",
      second_provider = "openrouter_claude",
    },
    behaviour = {
      enable_cursor_planning_mode = true,
    },
  },
  -- if you want to build from source then do `make BUILD_FROM_SOURCE=true`
  build = 'make',
  dependencies = {
    'stevearc/dressing.nvim',
    'nvim-lua/plenary.nvim',
    'MunifTanjim/nui.nvim',
    'echasnovski/mini.icons',
    'zbirenbaum/copilot.lua',
    {
      'MeanderingProgrammer/render-markdown.nvim',
      opts = {
        file_types = { 'markdown', 'Avante' }
      },
      ft = { 'markdown', 'Avante' }
    },
    {
      'HakonHarnes/img-clip.nvim',
      event = 'VeryLazy',
      opts = {
        default = {
          embed_image_as_base64 = false,
          prompt_for_file_name = false,
          drag_and_drop = {
            insert_mode = true
          }
        }
      }
    },
    {
      'saghen/blink.cmp',
      opts = {
        sources = {
          default = {
            { 'avante_commands', 'avante_mentions', 'avante_files' }
          },
          providers = {
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
          }
        }
      }
    }
  }

}
