local utils = require('utils')

local function setup()
  local review = require('claude-review')
  review.setup()

  utils.keymap({ 'n', 'v' }, '<leader>aa', review.add, 'Claude: add comment')
  utils.keymap('n', '<leader>ac', review.show, 'Claude: show comment thread')
  utils.keymap('n', '<leader>ae', review.edit, 'Claude: edit comment')
  utils.keymap('n', '<leader>ar', review.follow_up, 'Claude: follow-up')
  utils.keymap(
    { 'n', 'v' },
    '<leader>ad',
    review.delete,
    'Claude: delete comment'
  )
  utils.keymap('n', '<leader>aD', function()
    review.delete({ line1 = 1, line2 = vim.api.nvim_buf_line_count(0) })
  end, 'Claude: delete comments in file')
  utils.keymap('n', '<leader>aR', review.resolve, 'Claude: toggle resolved')
  utils.keymap('n', '<leader>as', review.send, 'Claude: send comment')
  utils.keymap('n', '<leader>aS', review.send_all, 'Claude: send all drafts')
  utils.keymap('n', '<leader>al', review.list, 'Claude: list comments')
  utils.keymap('n', '<leader>af', function()
    review.list({ picker = 'fzf' })
  end, 'Claude: pick comment')
end

return {
  {
    dir = vim.fs.joinpath(
      vim.fn.stdpath('config'),
      'dev',
      'claude-review.nvim'
    ),
    setup = setup,
  },
}
