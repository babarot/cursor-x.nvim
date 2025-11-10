--- cursor-x.nvim
--- Automatically highlight the cursorline and cursorcolumn after a configurable delay
--- @module cursor-x

local highlight = require("cursor-x.highlight")
local instance = highlight.new()

local M = {}

--- Setup cursor-x plugin
--- @param opt table|nil Configuration options
---   - interval: number (default: 1000) - Time in ms before highlighting appears
---   - always_cursorline: boolean (default: false) - Always show cursorline
---   - filetype_exclude: table (default: {}) - Filetypes to exclude
---   - buftype_exclude: table (default: {}) - Buffer types to exclude
---   - highlight_cursor_line: string (default: "Visual") - Highlight group for cursor line
---   - highlight_cursor_column: string (default: "Visual") - Highlight group for cursor column
function M.setup(opt)
  instance:setup(opt)
end

--- Enable cursor highlighting globally
function M.enable()
  instance:enable()
end

--- Disable cursor highlighting globally
function M.disable()
  instance:disable()
end

return M
