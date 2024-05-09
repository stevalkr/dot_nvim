local M = {}
local utils = require('utils')

M.config = function()
  require('gitsigns').setup({
    current_line_blame = true,
    current_line_blame_opts = {
      virt_text = true,
      -- 'eol' | 'overlay' | 'right_align'
      virt_text_pos = 'eol',
      delay = 500,
      ignore_whitespace = false,
      virt_text_priority = 100,
    },
    on_attach = function(bufnr)
      local gs = package.loaded.gitsigns
      local kopts = { buffer = bufnr }

      -- Actions
      utils.keymap('n', '<leader>hs',
        gs.stage_hunk, 'Stage hunk',
        kopts
      )

      utils.keymap('n', '<leader>hr',
        gs.reset_hunk, 'Reset hunk',
        kopts
      )

      utils.keymap('v', '<leader>hs',
        function()
          gs.stage_hunk { vim.fn.line('.'), vim.fn.line('v') }
        end, 'Stage hunk',
        kopts
      )

      utils.keymap('v', '<leader>hr',
        function()
          gs.reset_hunk { vim.fn.line('.'), vim.fn.line('v') }
        end, 'Reset hunk',
        kopts
      )

      utils.keymap('n', '<leader>hS',
        gs.stage_buffer, 'Stage buffer hunks',
        kopts
      )

      utils.keymap('n', '<leader>hu',
        gs.undo_stage_hunk, 'Undo stage hunk',
        kopts
      )

      utils.keymap('n', '<leader>hR',
        gs.reset_buffer, 'Reset buffer hunks',
        kopts
      )

      utils.keymap('n', '<leader>hp',
        gs.preview_hunk, 'Preview hunk',
        kopts
      )

      utils.keymap('n', '<leader>hB',
        function()
          gs.blame_line { full = true }
        end, 'Blame line',
        kopts
      )

      utils.keymap('n', '<leader>hb',
        gs.toggle_current_line_blame, 'Current line blame',
        kopts
      )

      utils.keymap('n', '<leader>hd',
        gs.diffthis, 'Diff this',
        kopts
      )

      utils.keymap('n', '<leader>hD',
        function()
          gs.diffthis('~')
        end, 'Diff this HEAD',
        kopts
      )

      utils.keymap('n', '<leader>ht',
        gs.toggle_deleted, 'Toggle deleted',
        kopts
      )

      -- Text object
      utils.keymap({ 'o', 'x' }, 'ih',
        '<Cmd>Gitsigns select_hunk<CR>', 'Select hunk',
        kopts
      )

      kopts.expr = true

      -- Navigation
      utils.keymap('n', ']h', function()
        if vim.wo.diff then
          vim.cmd.normal({ ']h', bang = true })
        else
          require('gitsigns').nav_hunk('next')
        end
      end, 'Next Hunk')

      utils.keymap('n', '[h', function()
        if vim.wo.diff then
          vim.cmd.normal({ '[h', bang = true })
        else
          require('gitsigns').nav_hunk('prev')
        end
      end, 'Prev Hunk')
    end
  })
end

return M
