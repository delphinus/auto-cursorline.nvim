local main = require("auto-cursorline.main").new()

---@param opts AutoCursorlineConfig?
local function setup(opts)
  main:setup(opts)
end

---@param opts AutoCursorlineDisableConfig?
local function disable(opts)
  main:disable(opts)
end

return { setup = setup, disable = disable, main = main }
