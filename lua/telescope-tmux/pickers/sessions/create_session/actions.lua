local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local utils = require("telescope-tmux.lib.utils")
local tutils = require("telescope.utils")
local popup = require("telescope-tmux.lib.popup")

local CreateSessionActions = {}

---@param prompt_bufnr number
---@param opts table
CreateSessionActions.on_select = function(prompt_bufnr, opts)
	local selection = action_state.get_selected_entry()
	local selected_folder = nil
	local selected_full_path = selection.value
	for parent_folder in string.gmatch(selected_full_path, "([^/]+)$") do -- get the last folder
		selected_folder = parent_folder
	end

	local TmuxSessions = require("telescope-tmux.core.sessions"):new(opts)
	local notifier = utils.get_notifier(opts)
	local new_session_name = selected_folder

	local new_session_id, err = TmuxSessions:create_session(new_session_name, selected_full_path)

	if err then
		-- this seems to be more robust to let Tmux do its name normaliztaion and check if the normalized name already exists or not
		if string.find(err, "duplicate session:") then
			local rename_session_cb = function(input)
				if input == nil then
					return
				end

				local new_session_id, err = TmuxSessions:create_session(input, selected_full_path)
				if err then
					notifier("Failed to create session: " .. err, vim.log.levels.ERROR)
					return
				end

				local error = TmuxSessions:switch_session(new_session_id)
				if error ~= nil then
					notifier(error, vim.log.levels.ERROR)
					return
				end

				return actions.close(prompt_bufnr)
			end
			popup.show_input(
				{
					prompt = "There is already an active session for this path.\nRename it or press Esc to cancel",
					default = new_session_name .. "_copy",
				},
				rename_session_cb
			)
		end
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
