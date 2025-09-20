return {

  {
    '3rd/image.nvim',
    build = false,
    enabled = vim.env.TMUX == nil,    -- https://github.com/3rd/image.nvim/issues/279
    init = function()
      if vim.env.HOMEBREW_PREFIX then -- TODO
        if vim.env.PKG_CONFIG_PATH then
          vim.fn.setenv(
            'PKG_CONFIG_PATH',
            string.format(
              '%s:%s/lib/pkgconfig:%s/share/pkgconfig',
              (vim.env.PKG_CONFIG_PATH or ''),
              vim.env.HOMEBREW_PREFIX,
              vim.env.HOMEBREW_PREFIX
            )
          )
        end
        if vim.env.PKG_CONFIG_PATH_FOR_TARGET then
          vim.fn.setenv(
            'PKG_CONFIG_PATH_FOR_TARGET',
            string.format(
              '%s:%s/lib/pkgconfig:%s/share/pkgconfig',
              (vim.env.PKG_CONFIG_PATH_FOR_TARGET or ''),
              vim.env.HOMEBREW_PREFIX,
              vim.env.HOMEBREW_PREFIX
            )
          )
        end
      end
    end,
    opts = {}
  }
}
