local action_state = require("telescope.actions.state")
local actions = require("telescope.actions")
-- local enum = require("telescope-tmux.core.enums")
local finder = require("telescope-tmux.pickers.windows.switch_window.finder")
local popup = require("telescope-tmux.lib.popup")
local utils = require("telescope-tmux.lib.utils")

local SwitchActions = {}

---@param prompt_bufnr number
---@param opts table
SwitchActions.on_select = function(prompt_bufnr, opts)
  if
    not utils.notified_user_about_not_in_tmux_session(
      opts,
      "Not in a Tmux session, window switch is not possible",
      vim.log.levels.ERROR
    )
  then
    local TmuxWindows = require("telescope-tmux.core.windows"):new(opts)
    local selection = action_state.get_selected_entry()
    local notifier = utils.get_notifier(opts)
    if not selection then
      notifier("No such window.", vim.log.levels.ERROR)
      return
    end
    local value = selection.value

    local err = TmuxWindows:switch_window(value.session_id, value.window_id)
    if err ~= nil then
      notifier(err, vim.log.levels.ERROR)
      return
    end
  end
  actions.close(prompt_bufnr)
end

SwitchActions.rename_window = function(prompt_bufnr, opts)
  local selected_entry = action_state.get_selected_entry()
  local notifier = utils.get_notifier(opts)
  if not selected_entry then
    notifier("No window to rename", vim.log.levels.INFO)
    return
  end

  local selection = selected_entry.value
  local rename_callback = function(new_name)
    if not new_name then
      return
    end
    local TmuxWindows = require("telescope-tmux.core.windows"):new(opts)
    local err = TmuxWindows:rename_window(selection.session_id, selection.window_id, new_name)
    if err then
      notifier("Failed to rename window: " .. err, vim.log.levels.ERROR)
    end

    utils.close_telescope_or_refresh(opts, prompt_bufnr, finder)
  end

  popup.show_input({
    prompt = "New name:",
    default = selection.window_name,
  }, rename_callback)
end

SwitchActions.kill_window = function(prompt_bufnr, opts)
  local selection = action_state.get_selected_entry()
  local current_picker = action_state.get_current_picker(prompt_bufnr)
  local multi_selection = current_picker:get_multi_selection()
  local current_session_id = require("telescope-tmux.core.tmux-state"):new(opts):get_session_id()

  local ids_to_kill = {}
  local prompt = "Kill the selected\nwindows (+ prefixed)? y/N"
  if #multi_selection > 0 then
    for _, window_data in pairs(multi_selection) do
      table.insert(ids_to_kill, window_data.value.window_id)
    end
  else
    prompt = "Kill the selected window:\n? y/N"
    table.insert(ids_to_kill, selection.value.window_id)
  end

  local kill_cb = function(answer)
    local accept_as_yes = { "yes", "Yes", "y", "Y", "YES", "yep" }
    if vim.tbl_contains(accept_as_yes, answer) then
      local TmuxWindows = require("telescope-tmux.core.windows"):new(opts)
      local notifier = utils.get_notifier(opts)
      for _, window_id in pairs(ids_to_kill) do
        local err = TmuxWindows:kill_window(current_session_id, window_id)
        if err then
          notifier("Failed to kill window: " .. err, vim.log.levels.ERROR)
        end
      end
    end

    utils.close_telescope_or_refresh(opts, prompt_bufnr, finder)
  end

  popup.show_input({ prompt = prompt }, kill_cb)
end

return SwitchActions
