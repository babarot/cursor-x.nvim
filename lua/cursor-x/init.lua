local main = require("cursor-x.main").new()

local function setup(opt)
  main:setup(opt)
end

local function disable()
  main:disable()
end

return { setup = setup, disable = disable }
