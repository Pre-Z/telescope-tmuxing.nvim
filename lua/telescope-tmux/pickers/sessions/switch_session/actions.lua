local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local utils = require("telescope-tmux.lib.utils")
local popup = require("telescope-tmux.lib.popup")
local finder = require("telescope-tmux.pickers.sessions.switch_session.finder")

local SwitchActions = {}

---@param prompt_bufnr number
---@param opts table
SwitchActions.on_select = function(prompt_bufnr, opts)
	if
		not utils.notified_user_about_session(
			opts,
			"Not in a Tmux session, session switch is not possible",
			vim.log.levels.ERROR
		)
	then
		local TmuxSessions = require("telescope-tmux.core.sessions"):new(opts)
		local selection = action_state.get_selected_entry()
		local err = TmuxSessions:switch_session(selection.value.id)
		if err ~= nil then
			local notifier = utils.get_notifier(opts)
			notifier(err, vim.log.levels.ERROR)
			return
		end
	end
	actions.close(prompt_bufnr)
end

SwitchActions.rename_session = function(prompt_bufnr, opts)
	local selection = action_state.get_selected_entry()
	local rename_callback = function(new_name)
    if not new_name then
      return
    end
		local TmuxSessions = require("telescope-tmux.core.sessions"):new(opts)
		local err = TmuxSessions:rename_session(selection.value.id, new_name)
		if err then
			local notifier = utils.get_notifier(opts)
			notifier("Failed to rename session: " .. err, vim.log.levels.ERROR)
		end

		utils.close_telescope_or_refresh(opts, prompt_bufnr, finder)
	end

	popup.show_input({
		prompt = "New name:",
		default = selection.value.name,
	}, rename_callback)
end

SwitchActions.delete_session = function(prompt_bufnr, opts)
	local selection = action_state.get_selected_entry()
	local current_picker = action_state.get_current_picker(prompt_bufnr)
	local multi_selection = current_picker:get_multi_selection()

	local ids_to_delete = {}
	local names_to_delete = {}
	local prompt = "Want to delete the selected\nsessions? y/N"
	if #multi_selection > 0 then
		for _, session_data in pairs(multi_selection) do
			table.insert(ids_to_delete, session_data.value.id)
			table.insert(names_to_delete, session_data.value.name)
		end
	else
		prompt = "Want to delete session:\n'" .. selection.value.name .. "'? y/N"
		table.insert(ids_to_delete, selection.value.id)
		table.insert(names_to_delete, selection.value.name)
	end

	local delete_cb = function(answer)
		local accept_as_yes = { "yes", "Yes", "y", "Y", "YES", "yep" }
		if vim.tbl_contains(accept_as_yes, answer) then
			local TmuxSessions = require("telescope-tmux.core.sessions"):new(opts)
			local notifier = utils.get_notifier(opts)
			for _, session_id in pairs(ids_to_delete) do
				local err = TmuxSessions:delete_session(session_id)
				if err then
					notifier("Failed to delete session: " .. err, vim.log.levels.ERROR)
				end
			end
		end

		utils.close_telescope_or_refresh(opts, prompt_bufnr, finder)
	end

	popup.show_input({ prompt = prompt }, delete_cb)
end

return SwitchActions
