local config = require("telescope-tmux.core.config")
local enums = require("telescope-tmux.core.enums")
local helper = require("telescope-tmux.lib.helper")
local tutils = require("telescope.utils")
local utils = require("telescope-tmux.lib.utils")

---@class TmuxSessions
local TmuxSessions = {}
TmuxSessions.__index = TmuxSessions

---@return TmuxSessions
function TmuxSessions:new(opts)
  local conf = config.reinit_config(opts)

  local obj = {}
  self.tstate = require("telescope-tmux.core.tmux-state"):new(conf)
  self.sort_sessions_by = conf.opts.sort_sessions
  self.sort_windows_by = conf.opts.sort_windows
  self.windows = require("telescope-tmux.core.windows"):new(opts)
  self.__notifier = utils.get_notifier(opts)

  setmetatable(obj, self)
  return obj
end

---@return TmuxSessionTable[]
function TmuxSessions:list_sessions(opts)
  local all_conf = config.reinit_config(opts)
  local conf = all_conf.opts
  local reverse_order = all_conf.sorting_strategy == enums.common.sorting.reversed_strategy and true or false
  if conf.list_sessions == enums.session.listing.type.simple then
    return self:list_sessions_simple()
  elseif conf.list_sessions == enums.session.listing.type.full then
    return self:list_sessions_with_windows(reverse_order)
  else
    return {}
  end
end

---@return TmuxSessionTable[]
function TmuxSessions:list_sessions_simple()
  local mapped_list = vim.tbl_map(function(tbl)
    tbl.display = tbl.session_name
    tbl.kind = "root"
    return tbl
  end, utils.order_list_by_property(self.tstate:get_session_list(), self.sort_sessions_by, enums.session.sorting.name))
  return mapped_list
end

---@param reverse_order boolean
function TmuxSessions:list_sessions_with_windows(reverse_order)
  local session_list =
    utils.order_list_by_property(self.tstate:get_session_list(), self.sort_sessions_by, enums.session.sorting.name)
  local final_list = {}
  for _, session_details in pairs(session_list) do
    local window_list = {}
    for _, details in pairs(session_details.windows) do
      table.insert(window_list, details)
    end

    local active_window_details = self.tstate:get_active_window_of_a_session(session_details.session_id)
    local active_window_name = active_window_details and active_window_details.window_name or ""
    local active_window_id = active_window_details and active_window_details.window_id or ""
    local inactive_windows = {}

    for _, window in pairs(window_list) do
      if window.window_id ~= active_window_id then
        table.insert(inactive_windows, window)
      end
    end
    local ordered_windows =
      utils.order_list_by_property(inactive_windows, self.sort_windows_by, enums.window.sorting.name)

    -- first add the session itself
    local connector = #ordered_windows == 0 and " ━ " or (reverse_order) and " ┗ " or " ┏ "
    table.insert(final_list, {
      display = session_details.session_name .. connector .. active_window_name,
      session_name = session_details.session_name,
      window_name = active_window_name,
      window_id = active_window_id,
      kind = enums.session.entity.kind.main,
      ordinal = session_details.session_name,
      session_id = session_details.session_id,
      last_used = session_details.last_used,
    })

    for index, window in pairs(ordered_windows) do
      -- onpy add window if it is not the active one, since it is being showed by the main session
      local separator = string.rep(" ", string.len(session_details.session_name))
      connector = index < #ordered_windows and " ┣ " or (reverse_order) and " ┏ " or " ┗ "
      local name = separator .. connector .. window.window_name
      table.insert(final_list, {
        session_id = session_details.session_id,
        session_name = session_details.session_name,
        window_name = window.window_name,
        display = name,
        kind = enums.session.entity.kind.sub,
        ordinal = session_details.session_name .. " " .. name,
        window_id = window.window_id,
        last_used = window.last_used,
      })
    end
  end

  return final_list
end

---@return TmuxSessionTable[]
function TmuxSessions:list_sessions_unordered()
  return self.tstate:get_session_list()
end

---@param session_name string
---@param cwd? string
---@return string | nil, string | nil
function TmuxSessions:create_session(session_name, cwd)
  local tmux_create_session_command = {
    "tmux",
    "new-session",
    "-dP",
    "-s",
    session_name,
    "-F",
    "#{session_id}:#{session_name}:#{window_id}:#{window_name}:#{window_active}",
  }

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
      session_name = new_session_name,
      windows = {
        [new_window_id] = new_window_name,
      },
    })
    -- self.tstate:update_states()
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

  err = err and err[1]
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

  err = err and err[1]

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
---@param window_id? string
---@return nil | string
function TmuxSessions:switch_session(session_id, window_id)
  local session_to_switch_to = self.tstate:get_session_details_by_session_id(session_id)
  if session_to_switch_to == nil then
    return "Cannot switch session, no session found with id: " .. session_id
  end

  local current_time = os.time()
  local current_session_id = self.tstate:get_session_id()
  local update_last_used_list = {}
  if current_session_id then
    table.insert(update_last_used_list, { session_id = current_session_id, last_used = current_time - 1 })
  end
  table.insert(update_last_used_list, { session_id = session_id, last_used = current_time })
  self.tstate:set_last_used_time_for_sessions(update_last_used_list)
  if window_id then
    self.windows:switch_window(session_id, window_id, current_time)
  end
  local id = window_id and session_id .. ":" .. window_id or session_id
  local command = string.format("silent !tmux switch-client -t '%s' -c '%s'", id, self.tstate:get_client_tty())
  vim.cmd(command)
end

function TmuxSessions:get_previous_session()
  local current_session_id = self.tstate:get_session_id()
  local previous_session = nil
  local ordered_list = utils.order_list_by_property(
    self.tstate:get_session_list(),
    enums.session.sorting.usage,
    enums.session.sorting.name
  )

  for _, v in pairs(ordered_list) do
    if v.session_id ~= current_session_id then
      previous_session = v
      break
    end
  end

  return previous_session
end

function TmuxSessions:switch_to_previous_session()
  local previous_session = self:get_previous_session()

  if previous_session ~= nil then
    self:switch_session(previous_session.session_id)
  else
    self.__notifier("No previous session to switch to", vim.log.levels.INFO)
  end
end

---@param session_id string
---@return {} | TmuxSessionTable
function TmuxSessions:get_session_data_by_id(session_id)
  return self.tstate:get_session_details_by_session_id(session_id) or {}
end

---@param session_name string
---@return string | nil
function TmuxSessions:get_session_id_by_name(session_name)
  for _, session_data in pairs(self.tstate:get_session_list()) do
    if session_name == session_data.session_name then
      return session_data.session_id
    end
  end
  return nil
end

return TmuxSessions
