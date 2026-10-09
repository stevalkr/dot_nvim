local M = {}

---@class PluginSpec
---@field src? string Repository URL managed by vim.pack.
---@field name? string Native package name.
---@field version? string|table Native revision or version range.
---@field dir? string Local checkout, outside vim.pack.
---@field init? function Runs before package scripts load.
---@field setup? function Runs eagerly after all runtime paths are available.
---@field build? function Runs after a managed package is installed or updated.
---@field dependencies? string[] Plugin names to initialize and configure first.

-- Discover only direct Lua files. Follow file symlinks used by this dotfiles tree.
---@param directory string
---@return PluginSpec[]
function M.discover(directory)
  local files = {}
  for file, kind, err in vim.fs.dir(directory, { err = true }) do
    assert(not err, err)
    if file:match('%.lua$') and (kind == 'file' or kind == 'link') then
      local path = vim.fs.joinpath(directory, file)
      local stat = vim.uv.fs_stat(path)
      assert(
        stat and stat.type == 'file',
        'Invalid plugin configuration: ' .. path
      )
      files[#files + 1] = path
    end
  end
  table.sort(files)
  local specs = {}
  for _, file in ipairs(files) do
    local configured = dofile(file)
    assert(
      type(configured) == 'table' and vim.islist(configured),
      'Plugin configuration must return a spec list: ' .. file
    )
    vim.list_extend(specs, configured)
  end
  return specs
end

local function plugin_name(spec)
  return spec.name or vim.fs.basename(spec.src or spec.dir):gsub('%.git$', '')
end

---@param specs PluginSpec[] Dependencies override the discovery order.
function M.setup(specs)
  assert(
    vim.fn.has('nvim-0.13') == 1,
    'This config requires Neovim 0.13 or newer'
  )
  assert(
    type(specs) == 'table' and vim.islist(specs),
    'Plugin specs must be a list'
  )
  local packages, builds, names = {}, {}, {}
  local allowed = {
    src = true,
    name = true,
    version = true,
    dir = true,
    init = true,
    setup = true,
    build = true,
    dependencies = true,
  }
  for i, spec in ipairs(specs) do
    assert(type(spec) == 'table', 'Invalid plugin spec at index ' .. i)
    for key in pairs(spec) do
      assert(allowed[key], 'Unknown plugin spec field: ' .. tostring(key))
    end
    assert(
      (spec.src ~= nil) ~= (spec.dir ~= nil),
      'Plugin spec must have exactly one of src or dir'
    )
    for _, callback in ipairs({ 'init', 'setup', 'build' }) do
      assert(
        spec[callback] == nil or type(spec[callback]) == 'function',
        'Invalid plugin callback: ' .. callback
      )
    end
    assert(
      spec.name == nil or (type(spec.name) == 'string' and spec.name ~= ''),
      'Invalid plugin name'
    )
    local name
    if spec.src then
      assert(
        type(spec.src) == 'string' and spec.src ~= '',
        'Invalid plugin source'
      )
      assert(
        spec.version == nil
          or type(spec.version) == 'string'
          or type(spec.version) == 'table',
        'Invalid plugin version'
      )
      name = plugin_name(spec)
      builds[name] = spec.build
    else
      assert(type(spec.dir) == 'string', 'Invalid local plugin directory')
      local stat = vim.uv.fs_stat(spec.dir)
      assert(
        stat and stat.type == 'directory',
        'Missing local plugin checkout: ' .. spec.dir
      )
      assert(
        spec.version == nil and spec.build == nil,
        'Local plugins cannot have version or build fields'
      )
      name = plugin_name(spec)
    end
    assert(not names[name], 'Duplicate plugin: ' .. name)
    assert(
      spec.dependencies == nil
        or (
          type(spec.dependencies) == 'table' and vim.islist(spec.dependencies)
        ),
      'Invalid dependencies for ' .. name
    )
    for _, dependency in ipairs(spec.dependencies or {}) do
      assert(
        type(dependency) == 'string' and dependency ~= '',
        'Invalid dependency for ' .. name
      )
    end
    names[name] = spec
  end

  -- A stable dependency traversal keeps alphabetical discovery deterministic.
  local ordered, visiting, visited = {}, {}, {}
  local function visit(spec)
    local name = plugin_name(spec)
    assert(not visiting[name], 'Plugin dependency cycle at ' .. name)
    if visited[name] then
      return
    end
    visiting[name] = true
    for _, dependency in ipairs(spec.dependencies or {}) do
      assert(
        names[dependency],
        'Missing dependency ' .. dependency .. ' for ' .. name
      )
      visit(names[dependency])
    end
    visiting[name] = nil
    visited[name] = true
    ordered[#ordered + 1] = spec
  end
  for _, spec in ipairs(specs) do
    visit(spec)
  end
  specs = ordered
  for _, spec in ipairs(specs) do
    if spec.src then
      packages[#packages + 1] =
        { src = spec.src, name = spec.name, version = spec.version }
    end
  end

  -- Generated package state belongs outside the Stow-managed config tree.
  local packlock = vim.fs.joinpath(vim.fn.stdpath('data'), 'nvim-pack-lock.json')
  if not vim.uv.fs_stat(packlock) then
    local seed = vim.fs.joinpath(vim.fn.stdpath('config'), 'nvim-pack-lock.json')
    if vim.uv.fs_stat(seed) then
      vim.fn.mkdir(vim.fn.stdpath('data'), 'p')
      assert(vim.uv.fs_copyfile(seed, packlock))
    end
  end
  vim.o.packlockfile = packlock
  local pending, initializing = {}, true
  local function run_builds()
    local current = pending
    pending = {}
    -- Keep the declared dependency order when several plugins change together.
    for _, spec in ipairs(packages) do
      local name = plugin_name(spec)
      if current[name] then
        vim.cmd.packadd(name)
        local ok, err = pcall(builds[name])
        if not ok then
          vim.notify(
            'Plugin build failed (' .. name .. '): ' .. tostring(err),
            vim.log.levels.ERROR
          )
        end
      end
    end
  end
  vim.api.nvim_create_autocmd('PackChanged', {
    group = vim.api.nvim_create_augroup('PluginBuilds', { clear = true }),
    callback = function(ev)
      if
        (ev.data.kind == 'install' or ev.data.kind == 'update')
        and builds[ev.data.spec.name]
      then
        pending[ev.data.spec.name] = true
        if not initializing then
          vim.schedule(run_builds)
        end
      end
    end,
  })

  for _, spec in ipairs(specs) do
    if spec.dir then
      vim.opt.rtp:append(spec.dir)
    end
  end
  for _, spec in ipairs(specs) do
    if spec.init then
      spec.init()
    end
  end
  if #packages > 0 then
    -- During init, native startup sources plugin scripts once after init.lua.
    vim.pack.add(packages)
  end
  for _, spec in ipairs(specs) do
    if spec.setup then
      spec.setup()
    end
  end
  initializing = false
  if next(pending) then
    if vim.v.vim_did_enter == 1 then
      run_builds()
    else
      -- UpdateRemotePlugins and other runtime commands exist after startup.
      vim.api.nvim_create_autocmd(
        'VimEnter',
        { once = true, callback = run_builds }
      )
    end
  end
end

return M
