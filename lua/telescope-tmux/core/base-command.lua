---@class TmuxCommandOptions
---@field command function

---@class TmuxCommand
---@field command function
local TmuxCommand = {}
TmuxCommand.__index = TmuxCommand

---@param opts TmuxCommandOptions
function TmuxCommand:new(opts)
  local obj = {}
  setmetatable(obj, self)
  self.command = opts.command
  return obj
end

function TmuxCommand:get_picker_for_telescope(opts)
  self.command(opts)
end

return TmuxCommand
