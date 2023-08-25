-- When CursorMoved,CursorMovedI occurs, it substitutes STATUS_CURSOR into
-- self.status. When WinEnter, it substitutes STATUS_WINDOW into self.status.
--
-- NOTE: When you enter in a new window, WinEnter AND CursorMoved events occur
-- some time. So cursor_moved() does nothing when self.status == STATUS_WINDOW,
-- that is, win_enter() has been called. When you move the cursor after that,
-- it sets 'nocursorline' at the first time.

local STATUS_DISABLED = 0
local STATUS_CURSOR = 1
local STATUS_WINDOW = 2

local uv = vim.uv or vim.loop

---@class AutoCursorline
---@field private wait_ms integer
---@field private status 0|1|2
---@field private enabled boolean
---@field private augroup_id integer?
---@field private timer uv_timer_t
---@field private disabled_buffers table<integer,boolean>
local AutoCursorline = {}

---@return AutoCursorline
function AutoCursorline.new()
  return setmetatable({
    wait_ms = 1000,
    status = STATUS_DISABLED,
    enabled = true,
    augroup_id = nil,
    timer = nil,
    disabled_buffers = {},
  }, { __index = AutoCursorline })
end

---@class AutoCursorlineConfig
---@field wait_ms integer default: 1000
---@field auto boolean default: true

---@param opts AutoCursorlineConfig?
---@return nil
function AutoCursorline:setup(opts)
  local config = vim.tbl_extend("force", { wait_ms = 1000, auto = true }, opts or {})
  self.wait_ms = config.wait_ms
  self:setup_events(config.auto)
  self.status = STATUS_CURSOR
  vim.wo.cursorline = true
end

---@param auto boolean
---@return nil
function AutoCursorline:setup_events(auto)
  if self.augroup_id and not auto then
    return
  end
  self.augroup_id = vim.api.nvim_create_augroup("auto-cursorline", {})

  ---@param events string[]
  ---@param method string
  local function create_au(events, method)
    vim.api.nvim_create_autocmd(events, {
      group = self.augroup_id,
      desc = "call auto-cursorline:" .. method .. "()",
      callback = function()
        if self:is_enabled() then
          self[method](self)
        end
      end,
    })
  end

  create_au({ "CursorMoved", "CursorMovedI" }, "cursor_moved")
  create_au({ "WinEnter" }, "win_enter")
  create_au({ "WinLeave" }, "win_leave")
end

---@return nil
function AutoCursorline:cursor_moved()
  if self.status == STATUS_WINDOW then
    self.status = STATUS_CURSOR
    return
  end
  self:timer_stop()
  self.timer = vim.defer_fn(function()
    self.status = STATUS_CURSOR
    vim.wo.cursorline = true
  end, self.wait_ms)
  if self.status == STATUS_CURSOR then
    vim.wo.cursorline = false
    self.status = STATUS_DISABLED
  end
end

---@return nil
function AutoCursorline:win_enter()
  vim.wo.cursorline = true
  self.status = STATUS_WINDOW
  self:timer_stop()
end

---@return nil
function AutoCursorline:win_leave()
  vim.wo.cursorline = false
  self:timer_stop()
end

---@return nil
function AutoCursorline:timer_stop()
  if self.timer and uv.is_active(self.timer) then
    self.timer:stop()
    self.timer:close()
  end
end

---@return nil
function AutoCursorline:enable()
  self.disabled_buffers = {}
  self.enabled = true
end

---@class AutoCursorlineDisableConfig
---@field buffer (boolean|integer)?

---@param opts AutoCursorlineDisableConfig?
---@return nil
function AutoCursorline:disable(opts)
  if opts and opts.buffer then
    local buf = type(opts.buffer) == "integer" and opts.buffer or vim.api.nvim_get_current_buf()
    self.disabled_buffers[buf] = true
  else
    self.enabled = false
  end
end

---@return boolean
function AutoCursorline:is_enabled()
  -- NOTE: For backward compatibility
  local buffer_disabled = vim.b.auto_cursorline_disabled == true or vim.b.auto_cursorline_disabled == 1
  local buf = vim.api.nvim_get_current_buf()
  return self.enabled
      and vim.bo.buftype ~= "terminal"
      and not self.disabled_buffers[buf]
      and not buffer_disabled
      and true
    or false
end

return AutoCursorline
