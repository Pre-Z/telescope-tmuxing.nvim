local TmuxState = require("telescope-tmux.core.tmux-state")
local config = require("telescope-tmux.core.config")
local enums = require("telescope-tmux.core.enums")
local helper = require("telescope-tmux.lib.helper")
local tutils = require("telescope.utils")
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
  end, utils.order_list_by_property(window_list, self.sort_by, enums.window.sorting.name))
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

  table.insert(
    update_last_used_list,
    { session_id = current_session_id, window_id = current_window_id, last_used = current_time - 1 }
  )
  table.insert(update_last_used_list, { session_id = session_id, window_id = window_id, last_used = current_time })

  self.tstate:set_last_used_time_for_windows(update_last_used_list)
  local id = session_id .. ":" .. window_id
  local command = string.format("silent !tmux switch-client -t '%s' -c '%s'", id, self.tstate:get_client_tty())
  vim.cmd(command)
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
  local _, _, err = tutils.get_os_command_output(command)

  err = err and err[1]
  if not err then
    self.tstate:update_states()
  end
  return err
end

---@param session_id string
---@param window_id string
---@return string | nil
function TmuxWindows:kill_window(session_id, window_id)
  local _, _, err = tutils.get_os_command_output({
    "tmux",
    "kill-window",
    "-t",
    string.format("%s:%s", session_id, window_id),
  })

  err = err and err[1]

  return err
end

---@param window_data_to_switch_to TmuxWindowTable
---@param window_data_to_kill TmuxWindowTable
---@return string | nil
function TmuxWindows:switch_to_window_and_kill_current(window_data_to_switch_to, window_data_to_kill)
  local command = string.format(
    "silent !tmux switch-client -t '%s:%s' -c '%s' \\; kill-window -t '%s:%s'",
    window_data_to_switch_to.session_id,
    window_data_to_switch_to.window_id,
    self.tstate:get_client_tty(),
    window_data_to_kill.session_id,
    window_data_to_kill.window_id
  )
  vim.cmd(command)
end

---@param session_data (TmuxWindowTable | TmuxSessionTable)?
---@return TmuxWindowTable | nil
function TmuxWindows:get_previous_window(session_data)
  local current_window_id = self.tstate:get_window_id()
  local previous_window = nil
  local session_list = session_data and session_data.window_list or self.tstate:get_all_window_list()
  local ordered_list = utils.order_list_by_property(session_list, enums.window.sorting.usage, enums.window.sorting.name)

  for _, v in pairs(ordered_list) do
    if v.window_id ~= current_window_id then
      previous_window = v
      break
    end
  end

  return previous_window
end

---@param session_data (TmuxWindowTable | TmuxSessionTable)?
function TmuxWindows:switch_to_previous_window(session_data)
  local previous_window = self:get_previous_window(session_data)

  if previous_window ~= nil then
    self:switch_window(previous_window.session_id, previous_window.window_id)
  else
    self.__notifier("No previous window to switch to", vim.log.levels.INFO)
  end
end

---@param session_id string
---@param window_name? string
---@param cwd? string
---@return string | nil, string | nil
function TmuxWindows:create_window(session_id, window_name, cwd)
  local tmux_create_session_command = {
    "tmux",
    "new-window",
    "-dP",
    "-t",
    session_id,
    "-F",
    "#{session_id}:#{session_name}:#{window_id}:#{window_name}:#{window_active}",
  }
  if window_name then
    tmux_create_session_command = helper.concat_simple_lists(tmux_create_session_command, { "-n", window_name })
  end

  if cwd then
    tmux_create_session_command = helper.concat_simple_lists(tmux_create_session_command, { "-c", cwd })
  end

  local new_session_details, _, err = tutils.get_os_command_output(tmux_create_session_command)

  err = err and err[1]
  if err then
    return nil, err
  end

  local new_session_id, new_session_name, new_window_id, new_window_name =
    utils.get_tmux_session_data_parts(new_session_details[1])

  if new_session_id then
    self.tstate:add_session_to_cache(new_session_id, {
      session_name = new_session_name, -- this is not changed, but the adder expects this
      windows = {
        [new_window_id] = new_window_name,
      },
    })
  end

  return new_window_id, err
end

---@param session_id string
---@param window_name string
---@return string | nil
function TmuxWindows:get_window_id_by_window_name_for_a_session(session_id, window_name)
  local window_list = self.tstate:get_window_list_of_a_session(session_id) or {}
  for _, window_data in pairs(window_list) do
    if window_name == window_data.window_name then
      return window_data.window_id
    end
  end
  return nil
end

return TmuxWindows
