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

local uv = vim.loop
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
    wait_ms = 1000,
    status = STATUS_DISABLED,
    enabled = true,
    augroup_id = nil,
    timer = nil,
  }, { __index = M })
end

function M:setup(opt)
  opt = opt or {}
  if opt.wait_ms then
    self.wait_ms = opt.wait_ms
  end
  self:setup_events(opt.force)
  self.status = STATUS_CURSOR
  vim.wo.cursorline = true
end

function M:setup_events(force)
  if self.augroup_id and not force then
    return
  end
  self.augroup_id = api.create_augroup("auto-cursorline", {})

  local function create_au(events, method)
    api.create_autocmd(events, {
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

function M:cursor_moved()
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
  if self.timer and uv.is_active(self.timer) then
    self.timer:stop()
    self.timer:close()
  end
end

function M:enable()
  vim.b.auto_cursorline_disabled = nil
  self.enabled = true
end

function M:disable(opt)
  opt = opt or {}
  if opt.buffer then
    vim.b.auto_cursorline_disabled = 1
  else
    self.enabled = false
  end
end

function M:is_enabled()
  -- For backward compatibility
  local buffer_disabled = vim.b.auto_cursorline_disabled == true or vim.b.auto_cursorline_disabled == 1
  return self.enabled and vim.bo.buftype ~= "terminal" and not buffer_disabled and true or false
end

return M
