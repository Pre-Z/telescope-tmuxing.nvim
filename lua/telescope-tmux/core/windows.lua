local TmuxState = require("telescope-tmux.core.tmux-state")
local config = require("telescope-tmux.core.config")
local tutils = require("telescope.utils")
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
  end, utils.order_list_by_property(window_list, self.sort_by, enum.window.sorting.name))
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




-- for debugging purpose
function table_print(tt, indent, done)
  done = done or {}
  indent = indent or 0
  if type(tt) == "table" then
    local sb = {}
    for key, value in pairs(tt) do
      table.insert(sb, string.rep(" ", indent)) -- indent it
      if type(value) == "table" and not done[value] then
        done[value] = true
        table.insert(sb, key .. " = {\n")
        table.insert(sb, table_print(value, indent + 2, done))
        table.insert(sb, string.rep(" ", indent)) -- indent it
        table.insert(sb, "}\n")
      elseif "number" == type(key) then
        table.insert(sb, string.format('"%s"\n', tostring(value)))
      else
        table.insert(sb, string.format('%s = "%s"\n', tostring(key), tostring(value)))
      end
    end
    return table.concat(sb)
  else
    return tt .. "\n"
  end
end

table_to_string = function(tbl)
  if "nil" == type(tbl) then
    return tostring(nil)
  elseif "table" == type(tbl) then
    return table_print(tbl)
  elseif "string" == type(tbl) then
    return tbl
  else
    return tostring(tbl)
  end
end


---@param session_id string
---@param window_id string
---@param new_name string
---@return string | nil
function TmuxWindows:rename_window(session_id, window_id, new_name)
  local command = {
		"tmux",
		"rename-window",
		"-t",
		string.format("%s:%s", session_id, window_id),
		new_name,
  }
  print("the rename command:\n" .. table_to_string(command))
	local _, _, err = tutils.get_os_command_output(command)

	err = err and err[1]
	if not err then
		self.tstate:update_states()
	end
	return err
end



return TmuxWindows
