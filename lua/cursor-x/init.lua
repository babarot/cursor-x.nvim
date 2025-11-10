--- cursor-x.nvim
--- Automatically highlight the cursorline and cursorcolumn after a configurable delay

local main = require("cursor-x.main").new()

--- Setup cursor-x plugin
--- @param opt table|nil Configuration options
---   - interval: number (default: 1000) - Time in ms before highlighting appears
---   - always_cursorline: boolean (default: false) - Always show cursorline
---   - filetype_exclude: table (default: {}) - Filetypes to exclude
---   - buftype_exclude: table (default: {}) - Buffer types to exclude
---   - highlight_cursor_line: string (default: "Visual") - Highlight group for cursor line
---   - highlight_cursor_column: string (default: "Visual") - Highlight group for cursor column
local function setup(opt)
  main:setup(opt)
end

--- Enable cursor highlighting globally
local function enable()
  main:enable()
end

--- Disable cursor highlighting globally
local function disable()
  main:disable()
end

return {
  setup = setup,
  enable = enable,
  disable = disable,
}
