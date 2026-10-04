local function setup()
  vim.api.nvim_create_user_command('GenerateDoc', function(args)
    require('ts-vimdoc').docgen({
      input_file = 'readme.md',
      output_file = 'doc/' .. args.args .. '.txt',
      project_name = args.args,
    })
    vim.cmd('helptags doc')
  end, { nargs = 1 })
end

return {
  {
    src = 'https://github.com/ibhagwan/ts-vimdoc.nvim',
    dependencies = { 'nvim-treesitter' },
    setup = setup,
  },
}
