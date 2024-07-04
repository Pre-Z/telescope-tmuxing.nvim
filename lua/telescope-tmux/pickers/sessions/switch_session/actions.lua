local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local utils = require("telescope-tmux.lib.utils")

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

return SwitchActions
