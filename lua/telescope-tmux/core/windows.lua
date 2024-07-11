local TmuxState = require("telescope-tmux.core.tmux-state")
local config = require("telescope-tmux.core.config")
local enum = require("telescope-tmux.core.enums")
local utils = require("telescope-tmux.lib.utils")

---@class TmuxWindow
local TmuxWindows = {}
TmuxWindows.__index = TmuxWindows

---@return TmuxWindow
function TmuxWindows:new(opts)
  local conf = config.reinit_config(opts)

  local obj = {}
  self.tstate = TmuxState:new(conf)
  self.sort_by = conf.opts.sort_windows
  self.__notifier = utils.get_notifier(opts)

  setmetatable(obj, self)
  return obj
end

---Gets the ordered window list of a session
---@param session_id string
---@return TmuxSessionTable[]
-- TODO: normalize the return type
function TmuxWindows:list_windows_of_session_id(session_id)
  local window_list = self.tstate:get_session_details_by_session_id(session_id).window_list

  return vim.tbl_map(function(tbl)
    tbl.display = tbl.window_name
    return tbl
  end, utils.order_list_by_property(window_list, self.sort_by, enum.sorting.session_name))
end

---@param session_id string
---@param window_id string
---@param current_time number?
---@return nil | string
function TmuxWindows:switch_window(session_id, window_id, current_time)
	local window_to_switch_to = self.tstate:get_window_details_by_ids(session_id, window_id)
	if window_to_switch_to == nil then
		return string.format("Cannot switch window, no window found with id: %s under session %s", window_id, session_id)
	end

	current_time = current_time or os.time()
	local current_window_id = self.tstate:get_window_id()
  local current_session_id = self.tstate:get_session_id()
	local update_last_used_list = {}

  table.insert(update_last_used_list, { session_id = current_session_id, window_id = current_window_id, last_used = current_time - 1 })
	table.insert(update_last_used_list, { session_id = session_id, window_id = window_id, last_used = current_time })

	self.tstate:set_last_used_time_for_windows(update_last_used_list)
	local id = session_id .. ":" .. window_id
	local command = string.format("silent !tmux switch-client -t '%s' -c '%s'", id, self.tstate:get_client_tty())
	vim.cmd(command)
end

return TmuxWindows
