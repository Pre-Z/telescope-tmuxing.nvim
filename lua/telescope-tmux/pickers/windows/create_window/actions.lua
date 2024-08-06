local action_state = require("telescope.actions.state")
local actions = require("telescope.actions")
local popup = require("telescope-tmux.lib.popup")
local utils = require("telescope-tmux.lib.utils")
local helper= require("telescope-tmux.lib.helper")

local CreateWindowActions = {}

---@param prompt_bufnr number
---@param opts table
CreateWindowActions.on_select = function(prompt_bufnr, opts)
  local selected_full_path = action_state.get_selected_entry().value
  if selected_full_path == "." or selected_full_path == "./" then
    selected_full_path = vim.fn.getcwd()
  end
  local selected_folder = helper.get_last_folder_name_on_path(selected_full_path)

  local TmuxWindows = require("telescope-tmux.core.windows"):new(opts)
  local TmuxState = require("telescope-tmux.core.tmux-state"):new(opts)
  local notifier = utils.get_notifier(opts)
  -- local new_window_name = selected_folder == "" and nil or selected_folder -- if the root directory is selected, do not keep the empty string as name
  local new_window_name = selected_folder
  local current_session_id = TmuxState:get_session_id()

  local new_window_id, err = TmuxWindows:create_window(current_session_id, new_window_name, selected_full_path)

  if err then
    local duplicate_window_name

    for match in string.gmatch(err, "duplicate window:%s?(.*)") do
      duplicate_window_name = match
    end

    -- this seems to be more robust to let Tmux do its name normaliztaion and check if the normalized name already exists or not
    if duplicate_window_name then
      local window_switch_cb = function()
        local window_id =
          TmuxWindows:get_window_id_by_window_name_for_a_session(current_session_id, duplicate_window_name)

        if window_id then
          TmuxWindows:switch_window(current_session_id, window_id)
        else
          notifier("Could not switch to window, failed to get session id", vim.log.levels.ERROR)
        end
      end

      local rename_window_cb = function(input)
        if not input then
          return
        end

        local created_window_id, create_window_err =
          TmuxWindows:create_window(current_session_id, input, selected_full_path)
        if create_window_err then
          notifier("Failed to create window: " .. create_window_err, vim.log.levels.ERROR)
          return
        end

        if created_window_id then
          local error = TmuxWindows:switch_window(current_session_id, created_window_id)
          if error ~= nil then
            notifier(error, vim.log.levels.ERROR)
            return
          end
        end

        return actions.close(prompt_bufnr)
      end

      local input_popup_cb = function()
        popup.show_input_center({
          prompt = "Type in the new name or press Esc to cancel",
          default = new_window_name .. "_copy",
        }, rename_window_cb)
      end

      local select_table = {
        [1] = { ["Switch to the active window"] = window_switch_cb },
        [2] = { ["Create new window with other name"] = input_popup_cb },
      }
      local selector_config = {
        prompt = "Duplicate window. Select or Esc to abort",
      }
      popup.show_selector(select_table, selector_config)
    end
    return
  end

  if not new_window_id then
    notifier("Failed to create new window", vim.log.levels.ERROR)
    return
  end

  local error = TmuxWindows:switch_window(current_session_id, new_window_id)
  if error ~= nil then
    notifier(error, vim.log.levels.ERROR)
    return
  end
  actions.close(prompt_bufnr)
end

return CreateWindowActions
