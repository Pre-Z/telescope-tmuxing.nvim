local tutils = require("telescope.utils")
local helper = require("telescope-tmux.lib.helper")
local TmuxState = require("telescope-tmux.core.tmux-state")
local config = require("telescope-tmux.core.config")
local utils = require("telescope-tmux.lib.utils")

local __reverse_sort_table = function(tbl)
	local keys = {}
	for k in pairs(tbl) do
		table.insert(keys, k)
	end
	table.sort(keys, function(a, b)
		return a > b
	end)
end

---@class TmuxSessions
---@field sort_by string
---@field tstate TmuxState
---@field __notifier function
local TmuxSessions = {}
TmuxSessions.__index = TmuxSessions

---@return TmuxSessions
function TmuxSessions:new(opts)
	local conf = config.reinit_config(opts)

	local obj = {}
	self.tstate = TmuxState:new(conf)
	self.sort_by = conf.opts.sort_sessions
	self.__notifier = utils.get_notifier(opts)

	setmetatable(obj, self)
	-- self.tstate:update_states()
	return obj
end

---@param tstate TmuxState
---@param order_property string
---@param second_order_property string?
local __get_ordered_session_list = function (tstate, order_property, second_order_property)
	-- no need to prepare for multiple sessions under the same name, since tmux does not let it to happen,
	-- in any other cases the primary and secondary ordering properties will be different
	second_order_property = second_order_property and second_order_property or "name"
  -- TODO: maybe deepcopy is needed
	local ordered_session_list = helper.shallow_copy_table(tstate:get_session_list())
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



---@return TmuxSessionTable[]
function TmuxSessions:list_sessions()
	return __get_ordered_session_list(self.tstate, self.sort_by)
end

---@return TmuxSessionTable[]
function TmuxSessions:list_sessions_unordered()

	return self.tstate:get_session_list()
end

---@param session_name string
---@param cwd? string
---@return string | nil, string:? Error
function TmuxSessions:create_session(session_name, cwd)
	local new_session_details, err = {}, {}
	local tmux_create_session_command = {
		"tmux",
		"new-session",
		"-dP",
		"-s",
		session_name,
		"-F",
		"#{session_id}:#{session_name}:#{window_id}:#{window_name}",
	}

	if cwd then
		tmux_create_session_command = helper.concat_simple_lists(tmux_create_session_command, { "-c", cwd })
	end

	new_session_details, _, err = tutils.get_os_command_output(tmux_create_session_command)

	err = err[1]
	if err then
		return nil, err
	end

	local new_session_id, new_session_name, new_window_id, new_window_name = utils.get_tmux_session_data_parts(new_session_details[1])

	if new_session_id then
		self.tstate:add_session_to_cache(new_session_id, {
      name = new_session_name,
      windows = {
        [new_window_id] = new_window_name
      }
    })
		self.tstate:update_states()
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

	err = err[1]
	if not err then
		self.tstate:update_states()
	end
	return err
end

---@param session_id string
---@return string | nil
function TmuxSessions:kill_session(session_id)
	local _, _, err = tutils.get_os_command_output({
		"tmux",
		"kill-session",
		"-t",
		session_id,
	})

	err = err[1]

	if not err then
		self.tstate:update_states()
	end
	return err
end

---@param session_id_to_switch string
---@return string | nil
function TmuxSessions:switch_to_session_and_kill_current(session_id_to_switch)
	local current_session_id = self.tstate:get_session_id()
	local command = string.format(
		"silent !tmux switch-client -t '%s' -c '%s' \\; kill-session -t '%s'",
		session_id_to_switch,
		self.tstate:get_client_tty(),
		current_session_id
	)
	vim.cmd(command)
end

---@param session_id string
---@return nil | string
function TmuxSessions:switch_session(session_id)

  local session_to_switch_to = self.tstate:get_session_details_by_session_id(session_id)
	if session_to_switch_to == nil then
		return "Cannot switch session, no session found with id: " .. session_id
	end

  local current_time = os.time()
	local current_session_id = self.tstate:get_session_id()
  local update_last_used_list = {}
	if current_session_id then
    table.insert(update_last_used_list, {id = current_session_id, last_used = current_time - 1})
	end
  table.insert(update_last_used_list, {id = session_id, last_used = current_time})
  self.tstate:set_last_used_time_for_sessions(update_last_used_list)
	local command = string.format("silent !tmux switch-client -t '%s' -c '%s'", session_id, self.tstate:get_client_tty())
	vim.cmd(command)
end

function TmuxSessions:get_previous_session()
	local current_session_id = self.tstate:get_session_id()
	local previous_session = nil

	for _, v in pairs(__get_ordered_session_list(self.tstate, "last_used")) do
		if v.id ~= current_session_id then
			previous_session = v
			break
		end
	end

	return previous_session
end

function TmuxSessions:switch_to_previous_session()
	local previous_session = self:get_previous_session()

	if previous_session ~= nil then
		self:switch_session(previous_session.id)
	else
		self.__notifier("No previous session to switch to", vim.log.levels.INFO)
	end
end

---@param session_id string
---@return {} | TmuxSessionTable
function TmuxSessions:get_session_data_by_id(session_id)
	return self.tstate:get_session_details(session_id) or {}
end

---@param session_name string
function TmuxSessions:get_session_id_by_name(session_name)
	for _, session_data in pairs(self.tstate:get_session_list()) do
		if session_name == session_data.name then
			return session_data.id
		end
	end
	return nil
end

return TmuxSessions
