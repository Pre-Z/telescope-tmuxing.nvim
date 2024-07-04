local tutils = require("telescope.utils")
local helper = require("telescope-tmux.lib.helper")
local TmuxState = require("telescope-tmux.core.tmux-state"):new()
local PersistentState = require("telescope-tmux.core.persistent-state")
local config = require("telescope-tmux.core.config")
local utils = require("telescope-tmux.lib.utils")
local next = next

---@class TmuxSessionTable
---@fields id string
---@fields name string
---@fields last_used number

---@type TmuxSessionTable[]
local __session_list = {}

---@class TmuxSessionsById
local __sessions_by_id = {}

---@param session_id string
---@param session_name string
local __add_session_to_session_cache = function(session_id, session_name)
	if __sessions_by_id[session_id] then
		__sessions_by_id[session_id].name = session_name -- force update the session_name
		-- __sessions_by_id[session_id].last_used = 0 -- reset the last_used?
	else
		__sessions_by_id[session_id] = { name = session_name, last_used = 0, id = session_id }
	end
	table.insert(__session_list, __sessions_by_id[session_id])
end

---@param session_id string
---@param session_name string
local __add_session_to_session_cache_and_pstate = function(session_id, session_name, pstate)
	__add_session_to_session_cache(session_id, session_name)
	pstate:write(__sessions_by_id)
end

local __merge_live_state_with_in_memory_state = function()
	local tmux_sessions_string_list, _, err =
		tutils.get_os_command_output({ "tmux", "list-sessions", "-F", "#{session_id}:#{session_name}" })

	if next(err) ~= nil then
		return
	end

	__session_list = {} -- empty current list

	local active_tmux_session_list = {}

	for _, session_string in pairs(tmux_sessions_string_list) do
		for id, name in string.gmatch(session_string, "($%d+):(.+)") do
			if id ~= nil then
				active_tmux_session_list[id] = name
			end
		end
	end

	for id in pairs(__sessions_by_id) do
		if not active_tmux_session_list[id] then
			__sessions_by_id[id] = nil
		end
	end

	for id, session_name in pairs(active_tmux_session_list) do
		__add_session_to_session_cache(id, session_name)
	end
end

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

local __reverse_sort_table = function(tbl)
	local keys = {}
	for k in pairs(tbl) do
		table.insert(keys, k)
	end
	table.sort(keys, function(a, b)
		return a > b
	end)
end

---@param order_property string
---@param second_order_property string?
local __get_ordered_session_list = function(order_property, second_order_property)
	-- no need to prepare for multiple sessions under the same name, since tmux does not let it to happen,
	-- in any other cases the primary and secondary ordering properties will be different
	second_order_property = second_order_property and second_order_property or "name"
	local ordered_session_list = helper.shallow_copy_table(__session_list)
	-- local sessions_by_order_property = {}

	table.sort(ordered_session_list, function(a, b)
		if a[order_property] == b[order_property] then
			return a[second_order_property] < b[second_order_property]
		else
			-- the last used should be the first in the list
			if order_property == "last_used" then
				return a[order_property] > b[order_property]
			elseif order_property == "name" then
				return a[order_property]:lower() < b[order_property]:lower()
			else
				return a[order_property] < b[order_property]
			end
		end
	end)

	return ordered_session_list
end

---@class TmuxSessions
---@field pstate PersistentState
---@field sort_by string
---@field __notifier function
local TmuxSessions = {}
TmuxSessions.__index = TmuxSessions

---@return TmuxSessions
function TmuxSessions:new(opts)
	local conf = config.reinit_config(opts)

	local obj = {}
	self.pstate = PersistentState:new(conf, "sessions.cache")
	self.sort_by = conf.opts.sort_sessions
  self.__notifier = utils.get_notifier(opts)

	setmetatable(obj, self)
	self:__syncronize_all_states()
	return obj
end

function TmuxSessions:__syncronize_all_states()
	__merge_state_with_persisted_state(self.pstate)
	__merge_live_state_with_in_memory_state()
	self.pstate:write(__sessions_by_id)
end

---@class SessionListOptions
---@fields format string?
---@return TmuxSessionTable[]
function TmuxSessions:list_sessions()
	self:__syncronize_all_states()

	return __get_ordered_session_list(self.sort_by)
end

---@param session_name string
---@return string | nil, string:? Error
function TmuxSessions:create_session(session_name)
	local new_session_id, err = nil, nil
	if not TmuxState:in_tmux_session() then
		err = "Not in Tmux Session"
	else
		new_session_id, _, err = tutils.get_os_command_output({
			"tmux",
			"new-session",
			"-dP",
			"-s",
			session_name,
			"-F",
			"#{session_id}",
		})
	end

	if new_session_id then
		__add_session_to_session_cache_and_pstate(new_session_id, session_name, self.pstate)
	end

	if not err then
		self:__syncronize_all_states()
	end
	return new_session_id, err
end

---@param session_id string
---@param new_name string
---@return string | nil
function TmuxSessions:rename_session(session_id, new_name)
	local _, _, err = tutils.get_os_command_output({
		"tmux",
		"rename-session",
		"-t",
		session_id,
		new_name,
	})

	if not err then
		self:__syncronize_all_states()
	end
	return err
end

---@param session_id string
---@return string | nil
function TmuxSessions:delete_session(session_id)
	local _, _, err = tutils.get_os_command_output({
		"tmux",
		"kill-session",
		"-t",
		session_id,
	})

	if not err then
		self:__syncronize_all_states()
	end
	return err
end

---@param session_id string
---@return nil | string
function TmuxSessions:switch_session(session_id)
	local current_time = os.time()

	if __sessions_by_id[session_id] == nil then
		return "Cannot switch session, no session found with id: " .. session_id
	end

	local current_session_id = TmuxState:get_session_id()
	__sessions_by_id[current_session_id].last_used = current_time - 1
	__sessions_by_id[session_id].last_used = current_time
	local session_name = __sessions_by_id[session_id].name
	self:__syncronize_all_states()
	vim.cmd(string.format('silent !tmux switchc -t "%s" -c "%s"', session_name, TmuxState:get_client_tty()))
end

function TmuxSessions:switch_to_previous_session()
	local current_session_id = TmuxState:get_session_id()
	local previous_session = nil
  self:__syncronize_all_states()

	for _, v in pairs(__get_ordered_session_list("last_used")) do
		if v.id ~= current_session_id then
			previous_session = v
			break
		end
	end

	if previous_session ~= nil then
		self:switch_session(previous_session.id)
  else
    self.__notifier("No previous session to switch to", vim.log.levels.INFO)
	end
end

return TmuxSessions
