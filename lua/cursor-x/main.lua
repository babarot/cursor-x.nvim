--- Status constants
local STATUS_DISABLED = 0
local STATUS_CURSOR = 1
local STATUS_WINDOW = 2

--- Cached vim.api wrapper for performance
local api = setmetatable({ _cache = {} }, {
  __index = function(self, name)
    if not self._cache[name] then
      local func = vim.api["nvim_" .. name]
      if func then
        self._cache[name] = func
      else
        error("Unknown api func: " .. name, 2)
      end
    end
    return self._cache[name]
  end,
})

--- @class CursorX
--- @field use boolean Whether the plugin is enabled
--- @field interval number Time in milliseconds before highlighting appears
--- @field always_cursorline boolean Whether to always show cursorline
--- @field highlight_cursor_line string Highlight group for cursor line
--- @field highlight_cursor_column string Highlight group for cursor column
--- @field status number Current status (DISABLED, CURSOR, or WINDOW)
--- @field augroup_id number|nil Autocommand group ID
--- @field timer userdata|nil Timer object
--- @field filetype_exclude table<string> List of filetypes to exclude
--- @field buftype_exclude table<string> List of buftypes to exclude
local M = {}

--- Create a new CursorX instance
--- @return CursorX
function M.new()
  return setmetatable({
    use = true,
    interval = 1000,
    always_cursorline = false,
    highlight_cursor_line = "Visual",
    highlight_cursor_column = "Visual",
    status = STATUS_DISABLED,
    augroup_id = nil,
    timer = nil,
    filetype_exclude = {},
    buftype_exclude = {},
  }, { __index = M })
end

--- Validate option value types
--- @param opt table User provided options
--- @return boolean, string|nil success, error_message
local function validate_options(opt)
  if opt.interval ~= nil then
    if type(opt.interval) ~= "number" or opt.interval <= 0 then
      return false, "interval must be a positive number"
    end
  end
  if opt.always_cursorline ~= nil and type(opt.always_cursorline) ~= "boolean" then
    return false, "always_cursorline must be a boolean"
  end
  if opt.filetype_exclude ~= nil and type(opt.filetype_exclude) ~= "table" then
    return false, "filetype_exclude must be a table"
  end
  if opt.buftype_exclude ~= nil and type(opt.buftype_exclude) ~= "table" then
    return false, "buftype_exclude must be a table"
  end
  if opt.highlight_cursor_line ~= nil and type(opt.highlight_cursor_line) ~= "string" then
    return false, "highlight_cursor_line must be a string"
  end
  if opt.highlight_cursor_column ~= nil and type(opt.highlight_cursor_column) ~= "string" then
    return false, "highlight_cursor_column must be a string"
  end
  return true, nil
end

--- Setup the plugin with user options
--- @param opt table|nil Configuration options
---   - interval: number (default: 1000) - Time in ms before highlighting appears
---   - always_cursorline: boolean (default: false) - Always show cursorline
---   - filetype_exclude: table (default: {}) - Filetypes to exclude
---   - buftype_exclude: table (default: {}) - Buffer types to exclude
---   - highlight_cursor_line: string (default: "Visual") - Highlight group for cursor line
---   - highlight_cursor_column: string (default: "Visual") - Highlight group for cursor column
---   - force: boolean (default: false) - Force recreate autocommands
function M:setup(opt)
  opt = opt or {}

  -- Validate options
  local ok, err = validate_options(opt)
  if not ok then
    vim.notify("cursor-x: " .. err, vim.log.levels.ERROR)
    return
  end

  -- Apply options
  if opt.interval then
    self.interval = opt.interval
  end
  if opt.always_cursorline ~= nil then
    self.always_cursorline = opt.always_cursorline
  end
  if opt.highlight_cursor_line then
    self.highlight_cursor_line = opt.highlight_cursor_line
  end
  if opt.highlight_cursor_column then
    self.highlight_cursor_column = opt.highlight_cursor_column
  end

  vim.wo.cursorline = self.always_cursorline
  self.filetype_exclude = opt.filetype_exclude or {}
  self.buftype_exclude = opt.buftype_exclude or {}  -- Fixed: was opt.buf_exclude
  self.status = STATUS_CURSOR
  self:setup_events(opt.force)
end

--- Setup autocommand events
--- @param force boolean|nil Force recreate autocommands even if already exist
function M:setup_events(force)
  if self.augroup_id and not force then
    return
  end
  self.augroup_id = api.create_augroup("cursor-x", {})

  local function create_au(events, method)
    api.create_autocmd(events, {
      group = self.augroup_id,
      desc = "call cursor-x:" .. method .. "()",
      callback = function()
        if self:enabled() then
          self[method](self)
        end
      end,
    })
  end

  create_au({ "CursorMoved", "CursorMovedI" }, "cursor_moved")
  create_au({ "WinEnter" }, "win_enter")
  create_au({ "WinLeave" }, "win_leave")
end

--- Toggle cursor highlighting
--- @param appear boolean Whether to show or hide cursor highlighting
function M:cursor(appear)
  if appear then
    if not self:enabled() then
      return
    end
    self.status = STATUS_CURSOR
    vim.wo.cursorline = true
    vim.wo.cursorcolumn = true
    -- Use configured highlight groups
    vim.cmd(string.format("highlight! link CursorLine %s", self.highlight_cursor_line))
    vim.cmd(string.format("highlight! link CursorColumn %s", self.highlight_cursor_column))
  else
    self.status = STATUS_DISABLED
    vim.wo.cursorline = self.always_cursorline
    vim.wo.cursorcolumn = false
    -- Restore default highlighting
    vim.cmd [[highlight! link CursorLine CursorLine]]
    vim.cmd [[highlight! link CursorColumn CursorColumn]]
  end
end

--- Handle cursor movement event
function M:cursor_moved()
  if self.status == STATUS_WINDOW then
    self.status = STATUS_CURSOR
    return
  end
  self:timer_stop()

  -- Create new timer using vim.loop for proper timer management
  self.timer = vim.loop.new_timer()
  if self.timer then
    self.timer:start(
      self.interval,
      0,
      vim.schedule_wrap(function()
        self:cursor(true)
      end)
    )
  end

  if self.status == STATUS_CURSOR then
    self:cursor(false)
  end
end

function M:win_enter()
  vim.wo.cursorline = true
  self.status = STATUS_WINDOW
  self:timer_stop()
end

function M:win_leave()
  vim.wo.cursorline = false
  self:timer_stop()
end

function M:timer_stop()
  if self.timer and vim.loop.is_active(self.timer) then
    self.timer:stop()
    self.timer:close()
  end
end

function M:enable()
  self.use = true
  self:cursor(true)
end

function M:disable()
  self.use = false
  self:cursor(false)
end

function M:enabled()
  local filetype = vim.bo.filetype
  local buftype = vim.bo.buftype
  for _, ft in ipairs(self.filetype_exclude) do
    if ft == filetype then
      return false
    end
  end
  for _, bt in ipairs(self.buftype_exclude) do
    if bt == buftype then
      return false
    end
  end
  return self.use
end

return M
