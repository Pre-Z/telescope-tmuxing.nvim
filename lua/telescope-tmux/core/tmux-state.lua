local tutils = require("telescope.utils")

local __tmux_client_tty = tutils.get_os_command_output({ "tmux", "display-message", "-p", "#{client_tty}" })[1]
local __in_tmux_session = tutils.get_os_command_output({ "printenv", "TMUX" })[1] ~= nil
local __tmux_session_id = tutils.get_os_command_output({"tmux", "display-message", "-p",  "#{session_id}"})[1]

---@class TmuxState
local TmuxState = {}
TmuxState.__index = TmuxState

---@return TmuxState
function TmuxState:new()
  local obj = {}

  setmetatable(obj, self)
  return obj
end

---@return string | nil
function TmuxState:get_client_tty()
  return __tmux_client_tty
end

---@return string | nil
function TmuxState:get_session_id()
  return __tmux_session_id
end

---@return boolean
function TmuxState:in_tmux_session()
 return __in_tmux_session
end

return TmuxState
