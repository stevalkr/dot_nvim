local utils = require('utils')
return {

  'lewis6991/gitsigns.nvim',
  event = { 'BufReadPre', 'BufNewFile' },

  opts = function()
    local gitsigns = require('gitsigns')
    return {
      signcolumn              = false,
      numhl                   = true,
      current_line_blame      = true,
      current_line_blame_opts = {
        virt_text = true,
        -- 'eol' | 'overlay' | 'right_align'
        virt_text_pos = 'eol',
        delay = 500,
        ignore_whitespace = false,
        virt_text_priority = 100,
      },
      attach_to_untracked     = true,

      on_attach               = function(bufnr)
        local kopts = { buffer = bufnr }

        -- Actions
        utils.keymap('n', '<leader>hs', gitsigns.stage_hunk, 'Stage hunk', kopts)
        utils.keymap('n', '<leader>hr', gitsigns.reset_hunk, 'Reset hunk', kopts)
        utils.keymap('v', '<leader>hs', function() gitsigns.stage_hunk({ vim.fn.line('.'), vim.fn.line('v') }) end,
          'Stage hunk', kopts)
        utils.keymap('v', '<leader>hr', function() gitsigns.reset_hunk({ vim.fn.line('.'), vim.fn.line('v') }) end,
          'Reset hunk', kopts)
        utils.keymap('n', '<leader>hu', gitsigns.undo_stage_hunk, 'Undo stage hunk', kopts)
        utils.keymap('n', '<leader>hS', gitsigns.stage_buffer, 'Stage buffer hunks', kopts)
        utils.keymap('n', '<leader>hR', gitsigns.reset_buffer, 'Reset buffer hunks', kopts)
        utils.keymap('n', '<leader>hp', gitsigns.preview_hunk, 'Preview hunk', kopts)
        utils.keymap('n', '<leader>hi', gitsigns.preview_hunk_inline, 'Preview hunk inline', kopts)
        utils.keymap('n', '<leader>hB', function() gitsigns.blame_line({ full = true }) end, 'Blame line', kopts)
        utils.keymap('n', '<leader>hb', gitsigns.toggle_current_line_blame, 'Current line blame', kopts)
        utils.keymap('n', '<leader>hd', gitsigns.diffthis, 'Diff this', kopts)
        utils.keymap('n', '<leader>hD', function() gitsigns.diffthis('~') end, 'Diff this HEAD', kopts)
        utils.keymap('n', '<leader>ht', gitsigns.toggle_deleted, 'Toggle deleted', kopts)
        utils.keymap('n', '<leader>hw', gitsigns.toggle_word_diff, 'Toggle word diff', kopts)

        -- Text object
        utils.keymap({ 'o', 'x' }, 'ih', gitsigns.select_hunk, 'Select hunk', kopts)

        -- Navigation
        kopts.expr = true

        utils.keymap('n', ']h', function()
          if vim.wo.diff then
            vim.cmd.normal({ ']h', bang = true })
          else
            gitsigns.nav_hunk('next')
          end
        end, 'Next Hunk')

        utils.keymap('n', '[h', function()
          if vim.wo.diff then
            vim.cmd.normal({ '[h', bang = true })
          else
            gitsigns.nav_hunk('prev')
          end
        end, 'Prev Hunk')
      end
    }
  end

}
