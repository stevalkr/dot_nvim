return {

  {
    'shaunsingh/nord.nvim',
    config = function()
      vim.cmd [[colorscheme nord]]
      vim.cmd [[highlight Normal guibg=NONE ctermbg=NONE]]
      vim.cmd [[highlight NonText guibg=NONE ctermbg=NONE]]
      vim.cmd [[highlight SignColumn guibg=NONE ctermbg=NONE]]
    end
  }

}
