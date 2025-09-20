local M = {}

---@param t table
---@return string
M.dump = function(t)
  if type(t) == 'table' then
    local s = '{ '
    for k, v in pairs(t) do
      if type(k) ~= 'number' then
        k = '"' .. k .. '"'
      end
      s = s .. '[' .. k .. '] = ' .. M.dump(v) .. ','
    end
    return s .. '} '
  else
    return tostring(t)
  end
end

M.capitalize = function()
  local hlsearch = vim.v.hlsearch
  vim.cmd([[execute "normal! \<Esc>"]])
  vim.cmd([[s/\%V\<.\%V/\u&/g]])
  vim.fn.histdel('/', -1)
  vim.fn.setreg('/', vim.fn.histget('/', -1))
  vim.v.hlsearch = hlsearch
end

---@param key string
M.smart_delete = function(key)
  vim.cmd.normal({
    (vim.fn.getline('.'):match('^%s*$') and '"_' or '') .. key,
    bang = true,
  })
end

M.format_project = function()
  local FILE_THRESHOLD = 1000

  local original_view = vim.fn.winsaveview()
  local original_buf = vim.api.nvim_get_current_buf()

  vim.notify('Scanning project files with `fd`...', vim.log.levels.INFO)

  vim.system({ 'fd', '--type', 'f' }, { text = true }, function(job)
    -- Check for errors from the fd command itself
    if job.code ~= 0 then
      vim.schedule(function()
        vim.notify(
          'Error running `fd`: ' .. (job.stderr or 'Unknown error'),
          vim.log.levels.ERROR
        )
      end)
      return
    end

    local files = vim.split(job.stdout, '\n', { trimempty = true })
    if #files > FILE_THRESHOLD then
      vim.schedule(function()
        vim.notify(
          string.format(
            'Found %d files, which exceeds the threshold of %d. Aborting.',
            #files,
            FILE_THRESHOLD
          ),
          vim.log.levels.WARN
        )
      end)
      return
    end

    if #files == 0 then
      vim.schedule(function()
        vim.notify('No files found to format.', vim.log.levels.INFO)
      end)
      return
    end

    local success_count = 0
    local files_processed = 0

    local function process_next_file(index)
      if index > #files then
        vim.api.nvim_set_current_buf(original_buf)
        vim.fn.winrestview(original_view)
        vim.schedule(function()
          vim.notify(
            string.format(
              'Project formatting complete. %d/%d files formatted.',
              success_count,
              files_processed
            ),
            vim.log.levels.INFO
          )
        end)
        return
      end

      vim.schedule(function()
        local on_format_done = function()
          if vim.bo.modified then
            vim.cmd.write()
            success_count = success_count + 1
          end
          process_next_file(index + 1)
        end

        local file_path = files[index]
        files_processed = files_processed + 1

        vim.cmd.edit(vim.fn.fnameescape(file_path))

        if M.has_plugin('conform') then
          require('conform').format(
            { bufnr = vim.api.nvim_get_current_buf(), async = true },
            function()
              on_format_done()
            end
          )
        else
          -- TODO: async if closed: https://github.com/neovim/neovim/issues/31206
          vim.lsp.buf.format({
            async = false,
            bufnr = vim.api.nvim_get_current_buf(),
          })
          on_format_done()
        end
      end)
    end

    process_next_file(1)
  end)
end

-- used for wezterm scrollback
M.colorize = function()
  local buf = vim.api.nvim_get_current_buf()

  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  while #lines > 0 and vim.trim(lines[#lines]) == '' do
    lines[#lines] = nil
  end
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, {})

  vim.b[buf].minianimate_disable = true

  vim.api.nvim_chan_send(
    vim.api.nvim_open_term(buf, {}),
    table.concat(lines, '\r\n')
  )
  vim.keymap.set('n', 'q', '<cmd>qa!<cr>', { silent = true, buffer = buf })
  vim.api.nvim_create_autocmd(
    'TextChanged',
    { buffer = buf, command = 'normal! G$' }
  )
  vim.api.nvim_create_autocmd(
    'TermEnter',
    { buffer = buf, command = 'stopinsert' }
  )

  vim.wo.relativenumber = false
  vim.wo.statuscolumn = ''
  vim.wo.signcolumn = 'no'
  vim.opt.listchars = { space = ' ' }

  vim.defer_fn(function()
    vim.b[buf].minianimate_disable = false
  end, 2000)
end

---@param name string
---@return boolean
M.has_plugin = function(name)
  local succ, mod = pcall(require, name)
  return succ and mod
end

---@generic T: table
---@param mode string|table
---@param lhs string
---@param rhs function|string
---@param desc string
---@param opts? T
M.keymap = function(mode, lhs, rhs, desc, opts)
  if vim.fn.has('nvim-0.11') == 1 then
    vim.validate('mode', mode, { 'string', 'table' })
    vim.validate('lhs', lhs, 'string')
    vim.validate('rhs', rhs, { 'string', 'function' })
    vim.validate('desc', desc, 'string')
    vim.validate('opts', opts, 'table', true)
  else
    vim.validate({
      mode = { mode, { 'string', 'table' } },
      lhs = { lhs, 'string' },
      rhs = { rhs, { 'string', 'function' } },
      desc = { desc, 'string' },
      opts = { opts, 'table', true },
    })
  end

  opts = vim.deepcopy(opts or {})
  opts = vim.tbl_deep_extend(
    'force',
    { desc = desc, remap = false, silent = true },
    opts
  )

  vim.keymap.set(mode, lhs, rhs, opts)
end

M.save_session = function()
  if not M.has_plugin('mini.sessions') then
    vim.notify('Plugin mini.sessions is not installed', vim.log.levels.ERROR)
    return false
  end
  local function buffer_filter(buf)
    if not vim.api.nvim_buf_is_valid(buf)
        or not vim.api.nvim_get_option_value('buflisted', { buf = buf }) then
      return false
    end
    return true
  end

  local buffers = vim.tbl_filter(buffer_filter, vim.api.nvim_list_bufs())

  local non_hidden_buffer = {}
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    non_hidden_buffer[vim.api.nvim_win_get_buf(win)] = true
  end

  for _, buffer in ipairs(buffers) do
    if non_hidden_buffer[buffer] == nil then
      if vim.api.nvim_get_option_value('modified', { buf = buffer }) then
        vim.notify(
          string.format('No write since last change for buffer %d', buffer),
          vim.log.levels.WARN
        )
      else
        vim.cmd('bdelete ' .. buffer)
      end
    end
  end

  vim.uv.fs_mkdir('.cache', 493, function(err) -- 0755
    -- Ignore if the directory already exists
    if err and not err:match('^EEXIST:') then
      vim.api.notify(err, vim.log.levels.ERROR)
    end
  end)

  require('mini.sessions').write('.cache/session.vim')
end

---@class AutocmdDefinition
---@field event string|table
---@field pattern? string|table
---@field command? string
---@field callback? string|fun(opts: table)
---@param definitions table<string, AutocmdDefinition[]>
M.augroup = function(definitions)
  for group_name, definition in pairs(definitions) do
    vim.api.nvim_create_augroup(group_name, { clear = true })
    for _, def in ipairs(definition) do
      vim.api.nvim_create_autocmd(def.event, {
        pattern = def.pattern,
        group = group_name,
        command = def.command,
        callback = def.callback,
      })
    end
  end
end

return M
