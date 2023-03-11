local config = {}
local M = {}

local function enabled(
  filetype, filetype_exclude,
  buftype, buftype_exclude
)
  for _, ft in ipairs(filetype_exclude) do
    if ft == filetype then
      return false
    end
  end
  for _, bt in ipairs(buftype_exclude) do
    if bt == buftype then
      return false
    end
  end
  return true
end

M.setup = function(options)
  config = options
end

M.appear = function(yes)
  if not enabled(
        vim.bo.filetype, config.filetype_exclude or {},
        vim.bo.buftype, config.buftype_exclud or {}
      ) then
    return
  end
  if yes then
    vim.opt.cursorcolumn = true
    vim.cmd [[highlight! link CursorLine Visual]]
    vim.cmd [[highlight! link CursorColumn Visual]]
  else
    vim.opt.cursorcolumn = false
    vim.cmd [[highlight! link CursorLine CursorLine]]
    vim.cmd [[highlight! link CursorColumn CursorColumn]]
  end
end

return M
