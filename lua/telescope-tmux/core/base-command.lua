---@class TmuxCommandOptions
---@field command function

---@class TmuxCommand
---@field command function
local TmuxCommand = {}

---@param opts? TmuxCommandOptions
function TmuxCommand:new(opts)
  local obj = {}
  setmetatable(obj, self)
  if opts then
    self.command = opts.command
  end
  self.__index = self
  return obj
end

function TmuxCommand:get_picker_for_telescope(opts)
  self.command(opts)
end

return TmuxCommand
