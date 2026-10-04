return {
  {
    dir = vim.fs.joinpath(vim.fn.stdpath('config'), 'dev', 'sessions.nvim'),
    setup = function()
      require('sessions').setup()
    end,
  },
}
