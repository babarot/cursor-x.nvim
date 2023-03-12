local main = require("cursor-x.main").new()

local function setup(opt)
  main:setup(opt)
end

local function enable()
  main:enable()
end

local function disable()
  main:disable()
end

return {
  setup = setup,
  enable = enable,
  disable = disable,
}
