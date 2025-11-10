--- Core highlighting functionality for cursor-x.nvim
--- @module cursor-x.highlight

local config = require("cursor-x.config")

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

--- Create a new CursorX instance with default configuration
--- @return CursorX
function M.new()
  local defaults = config.defaults
  return setmetatable({
    use = true,
    interval = defaults.interval,
    always_cursorline = defaults.always_cursorline,
    highlight_cursor_line = defaults.highlight_cursor_line,
    highlight_cursor_column = defaults.highlight_cursor_column,
    status = STATUS_DISABLED,
    augroup_id = nil,
    timer = nil,
    filetype_exclude = defaults.filetype_exclude,
    buftype_exclude = defaults.buftype_exclude,
  }, { __index = M })
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
  local ok, err = config.validate(opt)
  if not ok then
    vim.notify("cursor-x: " .. err, vim.log.levels.ERROR)
    return
  end

  -- Merge with defaults and apply configuration
  local merged = config.merge(opt)

  self.interval = merged.interval
  self.always_cursorline = merged.always_cursorline
  self.highlight_cursor_line = merged.highlight_cursor_line
  self.highlight_cursor_column = merged.highlight_cursor_column
  self.filetype_exclude = merged.filetype_exclude
  self.buftype_exclude = merged.buftype_exclude

  vim.wo.cursorline = self.always_cursorline
  self.status = STATUS_CURSOR
  self:setup_events(opt.force)
  self:setup_commands()
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

--- Setup user commands
function M:setup_commands()
  -- Create user commands for enabling/disabling
  vim.api.nvim_create_user_command("CursorXEnable", function()
    self:enable()
  end, {
    desc = "Enable cursor-x highlighting",
  })

  vim.api.nvim_create_user_command("CursorXDisable", function()
    self:disable()
  end, {
    desc = "Disable cursor-x highlighting",
  })
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

--- Handle window enter event
function M:win_enter()
  vim.wo.cursorline = true
  self.status = STATUS_WINDOW
  self:timer_stop()
end

--- Handle window leave event
function M:win_leave()
  vim.wo.cursorline = false
  self:timer_stop()
end

--- Stop and cleanup the timer
function M:timer_stop()
  if self.timer then
    -- Check if timer is active before stopping
    local ok, is_active = pcall(vim.loop.is_active, self.timer)
    if ok and is_active then
      self.timer:stop()
    end
    -- Always try to close the timer handle
    if not self.timer:is_closing() then
      self.timer:close()
    end
    self.timer = nil
  end
end

--- Enable cursor highlighting globally
function M:enable()
  self.use = true
  self:cursor(true)
end

--- Disable cursor highlighting globally
function M:disable()
  self.use = false
  self:cursor(false)
end

--- Check if the plugin is enabled for the current buffer
--- @return boolean Whether highlighting is enabled
function M:enabled()
  if not self.use then
    return false
  end

  local filetype = vim.bo.filetype
  local buftype = vim.bo.buftype

  -- Check if current filetype is excluded
  for _, ft in ipairs(self.filetype_exclude) do
    if ft == filetype then
      return false
    end
  end

  -- Check if current buftype is excluded
  for _, bt in ipairs(self.buftype_exclude) do
    if bt == buftype then
      return false
    end
  end

  return true
end

return M
