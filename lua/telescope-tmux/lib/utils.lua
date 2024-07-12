local config = require("telescope-tmux.core.config")
local enums = require("telescope-tmux.core.enums")
local helper = require("telescope-tmux.lib.helper")
local tutils = require("telescope.utils")
local M = {}

---@param opts table -- the entire config table
M.get_notifier = function(opts)
  local conf = config.reinit_config(opts).opts
  local notifier

  if conf.use_nvim_notify == nil or conf.use_nvim_notify then
    local notify_plugin_available, notify = pcall(require, "notify")
    if conf.use_nvim_notify and not notify_plugin_available then
      vim.notify(
        "Nvim-notify plugin is not available, but was set to be used, fallbacking to vim.notify. Please install nvim-notify to be able to use it.",
        vim.log.levels.ERROR
      )
    end
    local nvim_notify_wrapper = function(message, level)
      notify(message, level, conf.nvim_notify)
    end
    notifier = notify_plugin_available and nvim_notify_wrapper or vim.notify
  else
    notifier = vim.notify
  end

  return notifier
end

---@param opts table -- the entire config table
---@param message string
---@param log_level number
---@return boolean
M.notified_user_about_not_in_tmux_session = function(opts, message, log_level)
  local notifier = M.get_notifier(opts)
  local TmuxState = require("telescope-tmux.core.tmux-state"):new(opts)

  if not TmuxState:in_tmux_session() then
    notifier(message, log_level)
    return true
  end

  return false
end

M.close_telescope_or_refresh = function(opts, prompt_bufnr, finder)
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  local conf = config.reinit_config(opts).opts

  if conf.keep_telescope_open then
    local current_picker = action_state.get_current_picker(prompt_bufnr)
    current_picker:refresh(finder(opts))
  else
    actions.close(prompt_bufnr)
  end
end

---@param session_string string
---@return string | nil, string | nil, string | nil, string | nil, boolean
M.get_tmux_session_data_parts = function(session_string)
  for session_id, session_name, window_id, window_name, window_active in
    string.gmatch(session_string, "([^:]*):([^:]*):([^:]*):([^:]*):([^:]*)")
  do
    return session_id, session_name, window_id, window_name, window_active == "1" and true or false
  end
end

-- source of the original implementation: https://github.com/camgraff/telescope-tmux.nvim/blob/cf857c1d28f6a5b0fd78ecb9d7c03fe95aa8eb3e/lua/telescope/_extensions/tmux/windows.lua
-- links the source window to a target window (useful for previewer applications)
M.link_tmux_window = function(src_window, target_window)
  local src = src_window or error("src_window is required")
  local target = target_window or error("target_window is required")
  return tutils.get_os_command_output({ "tmux", "link-window", "-kd", "-s", src, "-t", target })
end

---@param filename string
---@return boolean
M.file_exists = function(filename)
  return vim.fn.filereadable(filename) == 1
end

---@param list TmuxSessionTable[]
---@param order_property string
---@param second_order_property string
---@return TmuxSessionTable[] | TmuxWindowTable[]
M.order_list_by_property = function(list, order_property, second_order_property)
  -- no need to prepare for multiple sessions under the same name, since tmux does not let it to happen,
  -- in any other cases the primary and secondary ordering properties will be different
  -- TODO: maybe deepcopy is needed
  local ordered_list = helper.shallow_copy_table(list)
  -- local sessions_by_order_property = {}

  table.sort(ordered_list, function(a, b)
    if a[order_property] == b[order_property] then
      if string.find(second_order_property, enums.common.sorting.string.property_match_pattern) then
        return a[second_order_property]:lower() < b[second_order_property]:lower()
      end
      return a[second_order_property] < b[second_order_property]
    else
      if string.find(order_property, enums.common.sorting.reverse_ordering_property.property_match_pattern) then
        local a_value = helper.cut_off_pattern_from_string(
          a[order_property],
          enums.common.sorting.reverse_ordering_property.cut_pattern_for_value
        )
        local b_value = helper.cut_off_pattern_from_string(
          b[order_property],
          enums.common.sorting.reverse_ordering_property.cut_pattern_for_value
        )
        return a_value > b_value
      -- comparing as string
      elseif string.find(order_property, enums.common.sorting.string.property_match_pattern) then
        local a_value =
          helper.cut_off_pattern_from_string(a[order_property], enums.common.sorting.string.cut_pattern_for_value)
        local b_value =
          helper.cut_off_pattern_from_string(b[order_property], enums.common.sorting.string.cut_pattern_for_value)
        return a_value:lower() < b_value:lower()
      elseif string.find(order_property, enums.common.sorting.number.property_match_pattern) then
        local a_value =
          helper.cut_off_pattern_from_string(a[order_property], enums.common.sorting.number.cut_pattern_for_value)
        local b_value =
          helper.cut_off_pattern_from_string(b[order_property], enums.common.sorting.number.cut_pattern_for_value)
        return a_value < b_value
      else
        return a[order_property] < b[order_property]
      end
    end
  end)

  return ordered_list
end

M.get_active_window_id_name_of_a_session = function(session_id)
  local window_id_name = tutils.get_os_command_output({
    "tmux",
    "display-message",
    "-t",
    session_id,
    "-p",
    "#{window_id}:#{window_name}",
  })[1]
  for id, name in string.gmatch(window_id_name, "([^:]*):([^:]*)") do
    return id, name
  end
end

return M
