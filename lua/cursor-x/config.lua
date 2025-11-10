--- Configuration management for cursor-x.nvim
--- @module cursor-x.config

local M = {}

--- Default configuration
--- @class CursorXConfig
--- @field interval number Time in milliseconds before highlighting appears
--- @field always_cursorline boolean Whether to always show cursorline
--- @field filetype_exclude table<string> List of filetypes to exclude
--- @field buftype_exclude table<string> List of buffer types to exclude
--- @field highlight_cursor_line string Highlight group for cursor line
--- @field highlight_cursor_column string Highlight group for cursor column
M.defaults = {
  interval = 1000,
  always_cursorline = false,
  filetype_exclude = {},
  buftype_exclude = {},
  highlight_cursor_line = "Visual",
  highlight_cursor_column = "Visual",
}

--- Validate option value types
--- @param opt table User provided options
--- @return boolean success Whether validation passed
--- @return string|nil error_message Error message if validation failed
function M.validate(opt)
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

--- Merge user options with defaults
--- @param user_opts table|nil User provided options
--- @return CursorXConfig Merged configuration
function M.merge(user_opts)
  user_opts = user_opts or {}
  local config = vim.deepcopy(M.defaults)

  for key, value in pairs(user_opts) do
    if M.defaults[key] ~= nil then
      config[key] = value
    else
      vim.notify(
        string.format("cursor-x: Unknown option '%s'", key),
        vim.log.levels.WARN
      )
    end
  end

  return config
end

return M
