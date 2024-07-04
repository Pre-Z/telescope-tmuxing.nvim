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
		local TmuxSessions = require("telescope-tmux.core.sessions"):new(opts)
		local err = TmuxSessions:rename_session(selection.value.id, new_name)
		if err then
			local notifier = utils.get_notifier(opts)
			notifier("Failed to rename session: " .. err, vim.log.levels.ERROR)
		end
    -- rerun finder to have an updated session list
    -- TODO: try to restore cursor position
    local current_picker = action_state.get_current_picker(prompt_bufnr)
    current_picker:refresh(finder(opts))
	end

	popup.show_input({
		prompt = "New name:",
		default = selection.value.name,
	}, rename_callback)
end

return SwitchActions
