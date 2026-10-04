local M = {}

local function session_path()
  return vim.fs.joinpath(vim.fn.getcwd(), '.cache', 'session.vim')
end

function M.save()
  local path = session_path()
  local ok, err = pcall(vim.fs.mkdir, vim.fs.dirname(path), { parents = true })
  if not ok then
    vim.notify(
      'Cannot create session directory: ' .. tostring(err),
      vim.log.levels.ERROR
    )
    return false
  end

  local visible = {}
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    visible[vim.api.nvim_win_get_buf(win)] = true
  end
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if
      vim.api.nvim_buf_is_valid(buf)
      and vim.bo[buf].buflisted
      and not visible[buf]
    then
      if vim.bo[buf].modified then
        vim.notify(
          string.format('No write since last change for buffer %d', buf),
          vim.log.levels.WARN
        )
      else
        vim.api.nvim_buf_delete(buf, {})
      end
    end
  end

  ok, err = pcall(vim.cmd, 'mksession! ' .. vim.fn.fnameescape(path))
  if not ok then
    vim.notify('Cannot save session: ' .. tostring(err), vim.log.levels.ERROR)
    return false
  end
  vim.v.this_session = path
  vim.notify('Session saved: ' .. path)
  return true
end

local function has_startup_content()
  if vim.fn.argc() > 0 or vim.v.this_session ~= '' then
    return true
  end
  if vim.bo.filetype ~= '' or vim.bo.buftype ~= '' or vim.bo.modified then
    return true
  end
  local listed = 0
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[buf].buflisted then
      listed = listed + 1
    end
  end
  if listed > 1 then
    return true
  end
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  return #lines > 1 or (lines[1] or '') ~= ''
end

function M.setup()
  -- Capture the launch directory before any startup autocmd changes it.
  local path = session_path()
  vim.api.nvim_create_autocmd('VimEnter', {
    group = vim.api.nvim_create_augroup('ProjectSession', { clear = true }),
    once = true,
    nested = true,
    callback = function()
      if has_startup_content() or vim.fn.filereadable(path) ~= 1 then
        return
      end
      local ok, err =
        pcall(vim.cmd, 'silent source ' .. vim.fn.fnameescape(path))
      if not ok then
        vim.notify(
          'Cannot restore session: ' .. tostring(err),
          vim.log.levels.ERROR
        )
      end
    end,
  })
end

return M
