local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local utils = require("telescope-tmux.lib.utils")
local popup = require("telescope-tmux.lib.popup")

local CreateSessionActions = {}

---@param prompt_bufnr number
---@param opts table
CreateSessionActions.on_select = function(prompt_bufnr, opts)
	local selected_full_path = action_state.get_selected_entry().value
	local selected_folder = nil
	for parent_folder in string.gmatch(selected_full_path, "([^/]+)$") do -- get the last folder
		selected_folder = parent_folder
	end

	local TmuxSessions = require("telescope-tmux.core.sessions"):new(opts)
	local notifier = utils.get_notifier(opts)
	local new_session_name = selected_folder

	local new_session_id, err = TmuxSessions:create_session(new_session_name, selected_full_path)

	if err then
		local duplicate_session_name

		for match in string.gmatch(err, "duplicate session:%s?(.*)") do
			duplicate_session_name = match
		end

		-- this seems to be more robust to let Tmux do its name normaliztaion and check if the normalized name already exists or not
		if duplicate_session_name then
			local session_switch_cb = function()
				local session_id = TmuxSessions:get_session_id_by_name(duplicate_session_name)

				if session_id then
					TmuxSessions:switch_session(session_id)
				else
					notifier("Could not switch to session, failed to get session id", vim.log.levels.ERROR)
				end
			end

			local rename_session_cb = function(input)
				if not input then
					return
				end

				local created_session_id, create_session_err = TmuxSessions:create_session(input, selected_full_path)
				if create_session_err then
					notifier("Failed to create session: " .. create_session_err, vim.log.levels.ERROR)
					return
				end

				if created_session_id then
					local error = TmuxSessions:switch_session(created_session_id)
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
					default = new_session_name .. "_copy",
				}, rename_session_cb)
			end

			local select_table = {
				[1] = { ["Switch to the active session"] = session_switch_cb },
				[2] = { ["Create new session with other name"] = input_popup_cb },
			}
			local selector_config = {
				prompt = "Duplicate session. Select or Esc to abort",
			}
			popup.show_selector(select_table, selector_config)
		end
		return
	end

  if not new_session_id then
    notifier("Failed to create new session", vim.log.levels.ERROR)
    return
  end

	local error = TmuxSessions:switch_session(new_session_id)
	if error ~= nil then
		notifier(error, vim.log.levels.ERROR)
		return
	end
	actions.close(prompt_bufnr)
end

return CreateSessionActions
