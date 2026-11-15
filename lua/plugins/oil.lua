local utils = require('utils')

-- helper function to parse output
local function parse_output(proc)
  local result = proc:wait()
  local ret = {}
  if result.code == 0 then
    for line in
      vim.gsplit(result.stdout, '\n', { plain = true, trimempty = true })
    do
      line = line:gsub('/$', '')
      ret[line] = true
    end
  end
  return ret
end

-- Merge two status codes, letter by letter; mixed letters become 'M'.
-- Untracked children only show when nothing else changed.
local function merge_status(a, b)
  if not a or a == '??' then
    return b
  elseif b == '??' then
    return a
  end
  local ret = ''
  for i = 1, 2 do
    local x, y = a:sub(i, i), b:sub(i, i)
    ret = ret .. ((x == ' ' or x == y) and y or y == ' ' and x or 'M')
  end
  return ret
end

-- `git status` codes (lazygit's XY: staged, unstaged) keyed by entry name;
-- a directory gets the merged codes of its contents
local function parse_status(proc, prefix_proc)
  local result = proc:wait()
  local prefix = vim.trim(prefix_proc:wait().stdout or '')
  local ret = {}
  if result.code ~= 0 then
    return ret
  end
  local fields =
    vim.split(result.stdout, '\0', { plain = true, trimempty = true })
  local i = 1
  while i <= #fields do
    local code, path = fields[i]:sub(1, 2), fields[i]:sub(4)
    -- A rename or copy is followed by its source path.
    i = i + (code:find('[RC]') and 2 or 1)
    if vim.startswith(path, prefix) then
      local name = path:sub(#prefix + 1):match('^[^/]+')
      if name then
        ret[name] = merge_status(ret[name], code)
      end
    end
  end
  return ret
end

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
      local status_proc = vim.system(
        { 'git', '--no-optional-locks', 'status', '--porcelain', '-z', '.' },
        {
          cwd = key,
          text = true,
        }
      )
      local prefix_proc = vim.system({ 'git', 'rev-parse', '--show-prefix' }, {
        cwd = key,
        text = true,
      })
      local ret = {
        ignored = parse_output(ignore_proc),
        tracked = parse_output(tracked_proc),
        status = parse_status(status_proc, prefix_proc),
      }

      rawset(self, key, ret)
      return ret
    end,
  })
end

local git_status = new_git_status()

local function setup()
  local oil = require('oil')

  local refresh = require('oil.actions').refresh
  local orig_refresh = refresh.callback
  refresh.callback = function(...)
    git_status = new_git_status()
    orig_refresh(...)
  end

  -- Like lazygit: staged letter green, unstaged letter and untracked red
  local function set_hl()
    vim.api.nvim_set_hl(0, 'OilGitStaged', { link = 'Added', default = true })
    vim.api.nvim_set_hl(
      0,
      'OilGitUnstaged',
      { link = 'Removed', default = true }
    )
  end
  set_hl()

  local FIELD_NAME = require('oil.constants').FIELD_NAME
  require('oil.columns').register('git_status', {
    render = function(entry, _, bufnr)
      local dir = oil.get_current_dir(bufnr)
      local code = dir and git_status[dir].status[entry[FIELD_NAME]]
      if not code then
        return nil
      elseif code == '??' then
        return { code, 'OilGitUnstaged' }
      end
      return { code, { { 'OilGitStaged', 0, 1 }, { 'OilGitUnstaged', 1, 2 } } }
    end,
    parse = function(line)
      return line:match('^(%S+)%s+(.*)$')
    end,
  })

  -- Files change status on write, on oil's own changes, or outside nvim
  -- (lazygit) while unfocused.
  local view = require('oil.view')
  local function update_git_status()
    git_status = new_git_status()
    for _, bufnr in ipairs(view.get_all_buffers()) do
      if vim.bo[bufnr].modified then
        return
      end
    end
    view.rerender_all_oil_buffers({ refetch = false })
  end
  utils.augroup({
    oil_git_status = {
      { event = 'ColorScheme', callback = set_hl },
      {
        event = { 'BufWritePost', 'FocusGained' },
        callback = update_git_status,
      },
      {
        event = 'User',
        pattern = 'OilActionsPost',
        callback = update_git_status,
      },
    },
  })

  oil.setup({
    columns = {
      -- 'permissions',
      'mtime',
      'size',
      'git_status',
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
        local is_dotfile = vim.startswith(name, '.')
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
end

return {
  {
    src = 'https://github.com/stevearc/oil.nvim',
    dependencies = { 'mini.icons' },
    setup = setup,
  },
}
