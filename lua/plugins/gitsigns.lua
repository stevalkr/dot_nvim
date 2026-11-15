local function setup()
  -- Hunk keymaps live in codediff; gitsigns only shows status and blame.
  require('gitsigns').setup({
    signcolumn = false,
    numhl = true,
    current_line_blame = true,
    current_line_blame_opts = {
      virt_text = true,
      -- 'eol' | 'overlay' | 'right_align'
      virt_text_pos = 'eol',
      delay = 500,
      ignore_whitespace = false,
      virt_text_priority = 100,
    },
    attach_to_untracked = true,
  })
end

return {
  {
    src = 'https://github.com/lewis6991/gitsigns.nvim',
    setup = setup,
  },
}
