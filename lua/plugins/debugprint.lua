return {

  'andrewferrier/debugprint.nvim',
  lazy = false,
  dependencies = {
    'echasnovski/mini.hipatterns',
    'ibhagwan/fzf-lua',
  },

  opts = {
    keymaps = {
      normal = {
        plain_below = '<leader>rp',
        plain_above = '<leader>rP',
        variable_below = '<leader>rv',
        variable_above = '<leader>rV',
        surround_plain = '<leader>rsp',
        surround_variable = '<leader>rsv',
        textobj_below = '<leader>ro',
        textobj_above = '<leader>rO',
        textobj_surround = '<leader>rso',
        toggle_comment_debug_prints = '<leader>rc',
        delete_debug_prints = '<leader>rd',
      },
      visual = {
        variable_below = '<leader>rv',
        variable_above = '<leader>rV',
      },
    },
    print_tag = '🪵',
  },
}
