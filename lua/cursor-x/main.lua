local STATUS_DISABLED = 0
local STATUS_CURSOR = 1
local STATUS_WINDOW = 2

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

local M = {}

function M.new()
  return setmetatable({
    use = true,
    interval = 1000,
    always_cursorline = false,
    status = STATUS_DISABLED,
    augroup_id = nil,
    timer = nil,
  }, { __index = M })
end

function M:setup(opt)
  opt = opt or {}
  if opt.interval then
    self.interval = opt.interval
  end
  if opt.always_cursorline then
    self.always_cursorline = opt.always_cursorline
  end
  vim.wo.cursorline = opt.always_cursorline or false
  self.filetype_exclude = opt.filetype_exclude or {}
  self.buftype_exclude = opt.buf_exclude or {}
  self.status = STATUS_CURSOR
  self:setup_events(opt.force)
end

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

function M:cursor(appear)
  if appear then
    if not self:enabled() then
      return
    end
    self.status = STATUS_CURSOR
    vim.wo.cursorline = true
    vim.wo.cursorcolumn = true
    vim.cmd [[highlight! link CursorLine Visual]]
    vim.cmd [[highlight! link CursorColumn Visual]]
  else
    self.status = STATUS_DISABLED
    vim.wo.cursorline = self.always_cursorline
    vim.wo.cursorcolumn = false
    vim.cmd [[highlight! link CursorLine CursorLine]]
    vim.cmd [[highlight! link CursorColumn CursorColumn]]
  end
end

function M:cursor_moved()
  if self.status == STATUS_WINDOW then
    self.status = STATUS_CURSOR
    return
  end
  self:timer_stop()
  self.timer = vim.defer_fn(function()
    self:cursor(true)
  end, self.interval)
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
