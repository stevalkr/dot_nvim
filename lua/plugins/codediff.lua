local utils = require('utils')

-- codediff stages whole hunks only, so map visual staging to gitsigns, which
-- is attached to the working-tree buffer of a diff. Buffers are tracked per
-- tab so the maps leave with the diff.
local diff_tabs = {}

local function map_range(buf)
  for lhs, action in pairs({
    ['<leader>hs'] = 'stage_hunk',
    ['<leader>hr'] = 'reset_hunk',
  }) do
    utils.keymap('v', lhs, function()
      if not vim.b.gitsigns_status_dict then
        vim.notify('Selection is not in a working-tree buffer')
        return
      end
      require('gitsigns')[action]({ vim.fn.line('.'), vim.fn.line('v') })
    end, 'Git: ' .. action:gsub('_', ' ') .. ' (selection)', { buffer = buf })
  end
end

local function map_diff_buffers()
  for tab, bufs in pairs(diff_tabs) do
    if vim.api.nvim_tabpage_is_valid(tab) then
      for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
        local buf = vim.api.nvim_win_get_buf(win)
        if not bufs[buf] and not vim.bo[buf].filetype:match('^codediff') then
          bufs[buf] = true
          map_range(buf)
        end
      end
    end
  end
end

local function setup()
  local palette = require('nord.colors').palette
  local blend = require('nord.utils').blend
  local bg = palette.polar_night.origin

  -- Nord's reversed Diff* groups give full-strength line backgrounds, so tint
  -- lines lightly and keep the stronger tint for changed characters.
  require('codediff').setup({
    highlights = {
      line_insert = blend(palette.aurora.green, bg, 0.2),
      line_delete = blend(palette.aurora.red, bg, 0.2),
      char_insert = blend(palette.aurora.green, bg, 0.45),
      char_delete = blend(palette.aurora.red, bg, 0.45),
    },
    -- Ported from gitsigns; <leader>hs/hu/hr and ih are already the defaults.
    keymaps = {
      view = {
        next_hunk = ']h',
        prev_hunk = '[h',
        toggle_stage = { '-', '<leader>hS' },
        toggle_layout = { 't', '<leader>hi' },
      },
      explorer = {
        restore = { 'X', '<leader>hR' },
      },
    },
  })

  local group = vim.api.nvim_create_augroup('CodeDiffRange', { clear = true })
  vim.api.nvim_create_autocmd('User', {
    group = group,
    pattern = 'CodeDiffOpen',
    callback = function(ev)
      diff_tabs[ev.data.tabpage] = diff_tabs[ev.data.tabpage] or {}
      map_diff_buffers()
    end,
  })
  -- Selecting another file swaps the window buffers after the event fires.
  local function remap()
    if next(diff_tabs) then
      vim.schedule(map_diff_buffers)
    end
  end
  vim.api.nvim_create_autocmd(
    'BufWinEnter',
    { group = group, callback = remap }
  )
  vim.api.nvim_create_autocmd('User', {
    group = group,
    pattern = 'CodeDiffFileSelect',
    callback = remap,
  })
  vim.api.nvim_create_autocmd('User', {
    group = group,
    pattern = 'CodeDiffClose',
    callback = function(ev)
      for buf in pairs(diff_tabs[ev.data.tabpage] or {}) do
        if vim.api.nvim_buf_is_valid(buf) then
          pcall(vim.keymap.del, 'v', '<leader>hs', { buffer = buf })
          pcall(vim.keymap.del, 'v', '<leader>hr', { buffer = buf })
        end
      end
      diff_tabs[ev.data.tabpage] = nil
    end,
  })

  -- A status view scoped to the file diffs against the index and, unlike a
  -- revision diff, allows staging.
  utils.keymap('n', '<leader>hd', function()
    vim.cmd.CodeDiff({ '--', vim.fn.expand('%:p') })
  end, 'Diff file against index')
  utils.keymap('n', '<leader>hD', function()
    vim.cmd.CodeDiff({ 'file', 'HEAD~' })
  end, 'Diff file against HEAD~')
end

return {
  {
    src = 'https://github.com/esmuellert/codediff.nvim',
    dependencies = { 'nord.nvim' },
    setup = setup,
    build = function()
      vim.cmd.CodeDiff('install')
    end,
  },
}
