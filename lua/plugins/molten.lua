local utils = require('utils')
return {

  {
    'GCBallesteros/jupytext.nvim',
    opts = {
      style = 'markdown',
      output_extension = 'md',
      force_ft = 'markdown',
    },
  },

  {
    'jmbuhr/otter.nvim',
    dependencies = {
      'nvim-treesitter/nvim-treesitter',
    },
    opts = {},
  },

  {
    'benlubas/molten-nvim',
    dependencies = { '3rd/image.nvim' },
    build = ':UpdateRemotePlugins',
    ft = { 'ipynb', 'markdown', 'python' },

    init = function()
      vim.g.molten_image_provider = 'image.nvim'
      vim.g.molten_auto_open_output = false
      -- vim.g.molten_output_virt_lines = true

      vim.g.molten_virt_text_output = true
      vim.g.molten_virt_lines_off_by_1 = false

      vim.g.molten_wrap_output = true
      vim.g.molten_output_show_more = true
      vim.g.molten_output_win_max_height = 20

      local job = vim.system({ 'which', 'python3' }, { text = true }):wait()
      vim.g.python3_host_prog =
        vim.split(job.stdout, '\n', { trimempty = true })[1]
    end,

    config = function()
      utils.keymap(
        'n',
        '<leader>mi',
        '<Cmd>MoltenInit<CR>',
        'Initialize the plugin'
      )
      utils.keymap(
        'n',
        '<leader>re',
        '<Cmd>MoltenEvaluateOperator<CR>',
        'run operator selection'
      )
      utils.keymap(
        'n',
        '<leader>rl',
        '<Cmd>MoltenEvaluateLine<CR>',
        'evaluate line'
      )
      utils.keymap(
        'n',
        '<leader>rr',
        -- '<Cmd>MoltenReevaluateCell<CR>',
        function()
          local parser = vim.treesitter.get_parser()
          if not parser then
            vim.notify('No parser found', vim.log.levels.WARN)
            return
          end

          parser:parse()
          local file_lang = parser:lang()

          local row, col = unpack(vim.api.nvim_win_get_cursor(0))
          local range = { row - 1, col, row - 1, col + 1 }
          local ltree = parser:language_for_range(range)
          if not ltree then
            vim.notify('No syntax tree found', vim.log.levels.WARN)
            return
          end

          local lang = ltree:lang()
          if lang == file_lang then
            vim.notify('Not inside a code block', vim.log.levels.WARN)
            return
          end

          local trees = ltree:trees()
          for _, tree in ipairs(trees) do
            local node = tree:root()
            if vim.treesitter.node_contains(node, range) then
              local srow, _, erow, _ = node:range(false)
              vim.fn.setpos("'<", { 0, srow + 1, 1, 0 })
              vim.fn.setpos("'>", { 0, erow, vim.v.maxcol, 0 })
              vim.cmd([[MoltenEvaluateVisual]])
            end
          end
        end,
        're-evaluate cell'
      )
      utils.keymap('n', '<leader>ra', function()
        local parser = vim.treesitter.get_parser()
        if not parser then
          vim.notify('No parser found', vim.log.levels.WARN)
          return
        end

        local ts_tree = parser:parse()
        if not ts_tree or #ts_tree == 0 then
          vim.notify('No syntax tree found', vim.log.levels.WARN)
          return
        end

        local tree = ts_tree[1]
        local root = tree:root()

        local query = vim.treesitter.query.parse(
          'markdown',
          [[ (fenced_code_block (code_fence_content) @code) ]]
        )

        local cursor_row = vim.api.nvim_win_get_cursor(0)[1]
        for _, node in query:iter_captures(root, 0, 0, cursor_row) do
          local srow, _, erow, _ = node:range(false)

          if srow < cursor_row then
            vim.fn.setpos("'<", { 0, srow + 1, 1, 0 })
            vim.fn.setpos("'>", { 0, erow, vim.v.maxcol, 0 })
            vim.cmd([[MoltenEvaluateVisual]])
          end
        end
      end, 'run all code blocks up to cursor')
      utils.keymap(
        'v',
        '<leader>re',
        -- ':<C-u>MoltenEvaluateVisual<CR>`>j',
        function()
          vim.cmd([[execute "normal! \<Esc>"]])
          vim.cmd([[MoltenEvaluateVisual]])
        end,
        'evaluate visual selection'
      )
      utils.keymap(
        'n',
        '<leader>rd',
        '<Cmd>MoltenDelete<CR>',
        'molten delete cell'
      )
      utils.keymap(
        'n',
        '<leader>oh',
        '<Cmd>MoltenHideOutput<CR>',
        'hide output'
      )
      utils.keymap(
        'n',
        '<leader>os',
        '<Cmd>noautocmd MoltenEnterOutput<CR>',
        'show/enter output'
      )

      -- new notebook command
      local default_notebook = [[
  {
    "cells": [
     {
      "cell_type": "markdown",
      "metadata": {},
      "source": [
        ""
      ]
     }
    ],
    "metadata": {
     "kernelspec": {
      "display_name": "Python 3",
      "language": "python",
      "name": "python3"
     },
     "language_info": {
      "codemirror_mode": {
        "name": "ipython"
      },
      "file_extension": ".py",
      "mimetype": "text/x-python",
      "name": "python",
      "nbconvert_exporter": "python",
      "pygments_lexer": "ipython3"
     }
    },
    "nbformat": 4,
    "nbformat_minor": 5
  }
]]

      local function new_notebook(filename)
        local path = filename .. '.ipynb'
        local file = io.open(path, 'w')
        if file then
          file:write(default_notebook)
          file:close()
          vim.cmd('edit ' .. path)
        else
          print('Error: Could not open new notebook file for writing.')
        end
      end

      vim.api.nvim_create_user_command('NewNotebook', function(opts)
        new_notebook(opts.args)
      end, {
        nargs = 1,
        complete = 'file',
      })

      -- init molten buffer
      local imb = function(e)
        vim.schedule(function()
          local kernels = vim.fn.MoltenAvailableKernels()
          local try_kernel_name = function()
            local metadata =
              vim.json.decode(io.open(e.file, 'r'):read('a'))['metadata']
            return metadata.kernelspec.name
          end
          local ok, kernel_name = pcall(try_kernel_name)
          if not ok or not vim.tbl_contains(kernels, kernel_name) then
            kernel_name = nil
            local venv = os.getenv('VIRTUAL_ENV') or os.getenv('CONDA_PREFIX')
            if venv ~= nil then
              kernel_name = string.match(venv, '/.+/(.+)')
            end
          end
          if kernel_name ~= nil and vim.tbl_contains(kernels, kernel_name) then
            vim.cmd(('MoltenInit %s'):format(kernel_name))
          end
          vim.cmd('MoltenImportOutput')

          if utils.has_plugin('otter') then
            require('otter').activate()
          end
        end)
      end

      -- automatically import output chunks from a jupyter notebook
      vim.api.nvim_create_autocmd('BufAdd', {
        pattern = { '*.ipynb' },
        callback = imb,
      })

      -- we have to do this as well so that we catch files opened like nvim ./hi.ipynb
      vim.api.nvim_create_autocmd('BufEnter', {
        pattern = { '*.ipynb' },
        callback = function(e)
          if vim.api.nvim_get_vvar('vim_did_enter') ~= 1 then
            imb(e)
          end
        end,
      })

      -- automatically export output chunks to a jupyter notebook on write
      vim.api.nvim_create_autocmd('BufWritePost', {
        pattern = { '*.ipynb' },
        callback = function()
          if require('molten.status').initialized() == 'Molten' then
            vim.cmd('MoltenExportOutput!')
          end
        end,
      })
    end,
  },
}
