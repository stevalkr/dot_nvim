return {

  'L3MON4D3/LuaSnip',
  lazy = true,
  build = 'make install_jsregexp',

  config = function()
    require('luasnip').config.setup({
      region_check_events = 'CursorHold,InsertLeave,InsertEnter',
      delete_check_events = 'TextChanged,InsertEnter',
    })
  end,

}
