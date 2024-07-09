local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local utils = require("telescope-tmux.lib.utils")
local popup = require("telescope-tmux.lib.popup")
local finder = require("telescope-tmux.pickers.sessions.switch_session.finder")
local config = require("telescope-tmux.core.config")

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
		local err = TmuxSessions:switch_session(selection.value.session_id, selection.value.window_id)
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
		local err = TmuxSessions:rename_session(selection.value.session_id, new_name)
		if err then
			local notifier = utils.get_notifier(opts)
			notifier("Failed to rename session: " .. err, vim.log.levels.ERROR)
		end

		utils.close_telescope_or_refresh(opts, prompt_bufnr, finder)
	end

	popup.show_input({
		prompt = "New name:",
		default = selection.value.session_name,
	}, rename_callback)
end

SwitchActions.kill_session = function(prompt_bufnr, opts)
	local selection = action_state.get_selected_entry()
	local current_picker = action_state.get_current_picker(prompt_bufnr)
	local multi_selection = current_picker:get_multi_selection()

	local ids_to_kill = {}
	local names_to_kill = {}
	local prompt = "Kill the selected\nsessions? [y/N]"
	if #multi_selection > 0 then
		for _, session_data in pairs(multi_selection) do
			table.insert(ids_to_kill, session_data.value.session_id)
			table.insert(names_to_kill, session_data.value.session_name)
		end
	else
    -- TODO: make this name cut be dynamic
    local shortened_name = string.sub(selection.value.session_name, 1, 22)
    if string.len(shortened_name) < string.len(selection.value.session_name) then
      shortened_name = shortened_name .. "..."
    end
		prompt = "Kill session:\n'" .. shortened_name .. "'? [y/N]"
		table.insert(ids_to_kill, selection.value.session_id)
		table.insert(names_to_kill, selection.value.session_name)
	end

	local kill_cb = function(answer)
		local accept_as_yes = { "yes", "Yes", "y", "Y", "YES", "yep" }
		if not vim.tbl_contains(accept_as_yes, answer) then
			return
		end

		local TmuxSessions = require("telescope-tmux.core.sessions"):new(opts)
		local notifier = utils.get_notifier(opts)
		for _, session_id in pairs(ids_to_kill) do
			local err = TmuxSessions:kill_session(session_id)
			if err then
				notifier("Failed to kill session: " .. err, vim.log.levels.ERROR)
			end
		end
		utils.close_telescope_or_refresh(opts, prompt_bufnr, finder)
	end

	popup.show_input({ prompt = prompt }, kill_cb)
end

return SwitchActions
