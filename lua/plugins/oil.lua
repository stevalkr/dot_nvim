local utils = require('utils')

-- helper function to parse output
local function parse_output(proc)
  local result = proc:wait()
  local ret = {}
  if result.code == 0 then
    for line in
      vim.gsplit(result.stdout, '\n', { plain = true, trimempty = true })
    do
      -- Remove trailing slash
      line = line:gsub('/$', '')
      ret[line] = true
    end
  end
  return ret
end

-- build git status cache
local function new_git_status()
  return setmetatable({}, {
    __index = function(self, key)
      local ignore_proc = vim.system({
        'git',
        'ls-files',
        '--ignored',
        '--exclude-standard',
        '--others',
        '--directory',
      }, {
        cwd = key,
        text = true,
      })
      local tracked_proc = vim.system(
        { 'git', 'ls-tree', 'HEAD', '--name-only' },
        {
          cwd = key,
          text = true,
        }
      )
      local ret = {
        ignored = parse_output(ignore_proc),
        tracked = parse_output(tracked_proc),
      }

      rawset(self, key, ret)
      return ret
    end,
  })
end

local git_status = new_git_status()

-- Clear git status cache on refresh
return {

  'stevearc/oil.nvim',
  dependencies = { 'echasnovski/mini.icons' },

  config = function()
    local oil = require('oil')

    local refresh = require('oil.actions').refresh
    local orig_refresh = refresh.callback
    refresh.callback = function(...)
      git_status = new_git_status()
      orig_refresh(...)
    end

    oil.setup({
      columns = {
        -- 'permissions',
        'mtime',
        'size',
        'icon',
      },
      lsp_file_methods = {
        autosave_changes = 'unmodified',
      },
      keymaps = {
        ['g?'] = 'actions.show_help',
        ['yp'] = 'actions.copy_entry_path',
        ['<CR>'] = 'actions.select',
        ['J'] = 'actions.select_split',
        ['L'] = 'actions.select_vsplit',
        ['T'] = 'actions.select_tab',
        ['<C-p>'] = 'actions.preview',
        ['<C-r>'] = 'actions.refresh',
        ['<BS>'] = 'actions.parent',
        ['<C-e>'] = 'actions.open_cwd',
        ['<Esc><Esc>'] = 'actions.close',
        ['cd'] = 'actions.cd',
        ['tcd'] = 'actions.tcd',
        ['E'] = 'actions.open_cwd',
        ['S'] = 'actions.change_sort',
        ['H'] = 'actions.toggle_hidden',
        ['gy'] = 'actions.copy_to_system_clipboard',
        ['gp'] = 'actions.paste_from_system_clipboard',
        ['gP'] = {
          mode = 'n',
          callback = function()
            require('oil.clipboard').paste_from_system_clipboard({
              delete_original = true,
            })
          end,
          desc = 'Cut the system clipboard into the current oil directory',
        },
        ['<C-t>'] = 'actions.toggle_trash',
        -- ['<C-o>']      = 'actions.open_external',
        -- ['<C-d>']      = 'actions.preview_scroll_down',
        -- ['<C-u>']      = 'actions.preview_scroll_up',
        ['<leader>0'] = {
          mode = 'n',
          callback = function()
            if utils.has_plugin('nvim-0x0') then
              require('nvim-0x0').upload_oil_file({ append_filename = true })
            end
          end,
          desc = 'Upload current file',
        },
      },
      use_default_keymaps = false,
      view_options = {
        is_hidden_file = function(name, bufnr)
          local dir = oil.get_current_dir(bufnr)
          local is_dotfile = vim.startswith(name, '.') -- and name ~= '..'
          -- if no local directory (e.g. for ssh connections), just hide dotfiles
          if not dir then
            return is_dotfile
          end
          -- dotfiles are considered hidden unless tracked
          if is_dotfile then
            return not git_status[dir].tracked[name]
          else
            -- Check if file is gitignored
            return git_status[dir].ignored[name]
          end
        end,
      },
    })
    utils.keymap('n', ';e', oil.open, 'Open Oil')
    utils.keymap('n', ';E', oil.open_float, 'Open Oil in Float')
  end,
}
