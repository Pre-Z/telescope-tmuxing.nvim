local tutils = require("telescope.utils")
local PersistentState = require("telescope-tmux.core.persistent-state")
local utils = require("telescope-tmux.lib.utils")

local __in_tmux_session = tutils.get_os_command_output({ "printenv", "TMUX" })[1] ~= nil
local __tmux_session_id = tutils.get_os_command_output({ "tmux", "display-message", "-p", "#{session_id}" })[1]

---@class TmuxWindowTable
---@field id string
---@field name string
---@field last_used number

---@class TmuxSessionTable
---@field id string
---@field name string
---@field last_used number
---@field windows table<string, TmuxWindowTable> -- windows by window_id

---@type TmuxSessionTable[]
local __session_list = {}

---@class TmuxSessionsById
local __sessions_by_id = {}

local __add_window_data_to_session_id = function(session_id, windows)
  -- init windows if nonexistent
  if not __sessions_by_id[session_id].windows then
    __sessions_by_id[session_id].windows = {}
  end

	for window_id, window_name in pairs(windows) do
		if not __sessions_by_id[session_id].windows[window_id] then
			__sessions_by_id[session_id].windows[window_id] = { id = window_id, name = window_name, last_used = 0 }
		else
			__sessions_by_id[session_id].windows[window_id].name = window_name -- force update the window name
		end
	end
end

---@class TmuxSessionDetails
---@field name string | nil
---@field windows table<string, string | nil> -- window_id => window_name

---@param session_id string
---@param session_details TmuxSessionDetails
local __add_session_to_session_cache = function(session_id, session_details)
	if __sessions_by_id[session_id] then
		__sessions_by_id[session_id].name = session_details.name -- force update the session_name
    __add_window_data_to_session_id(session_id, session_details.windows)
		-- __sessions_by_id[session_id].last_used = 0 -- reset the last_used?
	else
		__sessions_by_id[session_id] = { name = session_details.name, last_used = 0, id = session_id }
    __add_window_data_to_session_id(session_id, session_details.windows)
	end
	table.insert(__session_list, __sessions_by_id[session_id])
end

local __merge_live_state_with_in_memory_state = function()
	local tmux_sessions_string_list, _, err = tutils.get_os_command_output({
		"tmux",
		"list-panes",
		"-a",
		"-F",
		"#{session_id}:#{session_name}:#{window_id}:#{window_name}",
	})

	err = err[1]
	if err then
		return {}
	end

	local active_tmux_session_list = {}

	for _, session_string in pairs(tmux_sessions_string_list) do
		local session_id, session_name, window_id, window_name = utils.get_tmux_session_data_parts(session_string)
		if session_id ~= nil then
			if not active_tmux_session_list[session_id] then
				active_tmux_session_list[session_id] = {
					name = session_name,
					windows = window_id ~= nil and { [window_id] = window_name } or {},
				}
			else
				if window_id then
					active_tmux_session_list[session_id].windows[window_id] = window_name
				end
			end
		end
	end

	__session_list = {} -- empty current list

	-- removing no longer existing session data
	for session_id in pairs(__sessions_by_id) do
		-- removing the nonexxistent session
		if not active_tmux_session_list[session_id] then
			__sessions_by_id[session_id] = nil
		else
			for window_id in pairs(__sessions_by_id[session_id].windows) do
				-- removing the nonexistent window
				if not active_tmux_session_list[session_id].windows[window_id] then
					__sessions_by_id[session_id].windows[window_id] = nil
				end
			end
		end
	end

	for id, session_details in pairs(active_tmux_session_list) do
		__add_session_to_session_cache(id, session_details)
	end
end

-- FIXME: windows should be handled also
local __merge_state_with_persisted_state = function(pstate)
	local saved_state = pstate:get()

	-- merge the in_memory data with the stored one
	for id, saved_session_prop in pairs(saved_state) do
		local in_mem_session_prop = __sessions_by_id[id]
		if in_mem_session_prop then
			if in_mem_session_prop.last_used < saved_session_prop.last_used then
				in_mem_session_prop.last_used = saved_session_prop.last_used
			end
			in_mem_session_prop.name = saved_session_prop.name
		else
			__sessions_by_id[id] = saved_session_prop
		end
	end
end

---@class TmuxState
---@field pstate PersistentState
local TmuxState = {}
TmuxState.__index = TmuxState

---@return TmuxState
function TmuxState:new(conf)
	local obj = {}

	self.pstate = PersistentState:new(conf, "sessions.cache")
	setmetatable(obj, self)
	return obj
end

function TmuxState:update_states()
	__merge_state_with_persisted_state(self.pstate)
	__merge_live_state_with_in_memory_state()
	self.pstate:write(__sessions_by_id)
end

---@class SessionLastUsedUpdateTable
---@field id string
---@field last_used number

---@param update_list SessionLastUsedUpdateTable[]
function TmuxState:set_last_used_time_for_sessions(update_list)
	for _, session in pairs(update_list) do
		if session.id then
			__sessions_by_id[session.id].last_used = session.last_used
		end
	end
	self:update_states()
end

---@param session_id string
---@param session_details TmuxSessionDetails
function TmuxState:add_session_to_cache(session_id, session_details)
	__add_session_to_session_cache(session_id, session_details)
	self.pstate:write(__sessions_by_id)
end

---@return TmuxSessionTable[]
function TmuxState:get_session_list()
	self:update_states()
	return __session_list
end

---@return TmuxSessionsById
function TmuxState:get_sessions_by_id_table()
	self:update_states()
	return __sessions_by_id
end

---@param session_id string
---@return TmuxSessionTable | nil
function TmuxState:get_session_details_by_session_id(session_id)
	return __sessions_by_id[session_id]
end

---@return string | nil
function TmuxState:get_client_tty()
	return tutils.get_os_command_output({ "tmux", "display-message", "-p", "#{client_tty}" })[1]
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
