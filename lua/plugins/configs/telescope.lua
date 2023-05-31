local M = {}


M.current_bufr_dir = function(prompt_bufnr)
  local fb_utils = require('telescope._extensions.file_browser.utils')
  local action_state = require('telescope.actions.state')
  local Path = require('plenary.path')

  local current_picker = action_state.get_current_picker(prompt_bufnr)
  local finder = current_picker.finder
  local bufr_path = Path:new(vim.fn.expand('#:p'))

  finder.path = bufr_path:parent():absolute()
  fb_utils.redraw_border_title(current_picker)
  fb_utils.selection_callback(current_picker, bufr_path:absolute())
  current_picker:refresh(
    finder,
    {
      new_prefix = fb_utils.relative_path_prefix(finder),
      reset_prompt = true,
      multi = current_picker._multi,
    }
  )
end

M.config = function(_, _opts)
  local actions = require('telescope.actions')
  local fb_actions = require('telescope').extensions.file_browser.actions

  require('telescope').setup({
    defaults = {
      mappings = {
        i = {
          ['<M-k>'] = actions.move_selection_previous,
          ['<M-j>'] = actions.move_selection_next,
        },
        n = {
          ['l'] = actions.select_horizontal,
          ['s'] = actions.select_tab,
          ['A'] = actions.select_all,
          ['v'] = actions.toggle_all,
          ['V'] = actions.drop_all
        }
      },
    },
    extensions = {
      fzf = {
        fuzzy = true,
        override_generic_sorter = true,
        override_file_sorter = true,
        case_mode = 'smart_case',
      },
      file_browser = {
        hijack_netrw = true,
        initial_mode = 'normal',
        mappings = {
          n = {
            ['c'] = nil,
            ['d'] = nil,
            ['g'] = nil,
            [';e'] = actions.close,
            ['N'] = fb_actions.create,
            ['r'] = fb_actions.rename,
            ['m'] = fb_actions.move,
            ['p'] = fb_actions.copy,
            ['dd'] = fb_actions.remove,
            ['o'] = fb_actions.open,
            ['h'] = fb_actions.goto_parent_dir,
            ['~'] = fb_actions.goto_home_dir,
            ['e'] = fb_actions.goto_cwd,
            ['E'] = M.current_bufr_dir,
            ['cd'] = fb_actions.change_cwd,
            ['f'] = fb_actions.toggle_browser,
            ['H'] = fb_actions.toggle_hidden,
            ['v'] = fb_actions.toggle_all,
            ['A'] = fb_actions.select_all
          },
        },
      },
      -- ['ui-select'] = {
      --   require('telescope.themes').get_dropdown {
      --     -- even more opts
      --   }
      -- },
      -- frecency = {
      -- 	show_scores = true,
      -- 	show_unindexed = true,
      -- 	ignore_patterns = { '*.git/*', '*/tmp/*' },
      -- },
    },
  })
  require('telescope').load_extension('fzf')
  require('telescope').load_extension('file_browser')
  -- require("telescope").load_extension("ui-select")

  local utils = require('telescope.utils')
  local builtin = require('telescope.builtin')
  local extensions = require('telescope').extensions
  local kopts = { noremap = true, silent = true }

  vim.keymap.set('n', ';f', builtin.find_files, kopts)
  vim.keymap.set('n', ';F', function()
    builtin.find_files({ cwd = utils.buffer_dir() })
  end, kopts)
  vim.keymap.set('n', ';g', builtin.live_grep, kopts)
  vim.keymap.set('v', ';g', builtin.grep_string, kopts)
  vim.keymap.set('n', ';b', builtin.buffers, kopts)
  vim.keymap.set('n', ';h', builtin.help_tags, kopts)
  vim.keymap.set('n', ';e', extensions.file_browser.file_browser, kopts)
  vim.keymap.set('n', ';E', function()
    extensions.file_browser.file_browser({ path = '%:p:h' })
  end, kopts)
end

return M
