local function setup()
  require('image').setup({
    max_width = 100,
    max_height = 12,
    max_height_window_percentage = math.huge,
    max_width_window_percentage = math.huge,
    window_overlap_clear_enabled = true,
    window_overlap_clear_ft_ignore = { 'cmp_menu', 'cmp_docs', '' },
  })
end

return {
  {
    src = 'https://github.com/3rd/image.nvim',
    dependencies = { 'nvim-treesitter' },
    setup = setup,
  },
}
