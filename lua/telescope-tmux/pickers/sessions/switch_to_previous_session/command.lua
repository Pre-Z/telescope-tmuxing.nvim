local TmuxCommand = require("telescope-tmux.core.base-command")

return TmuxCommand:new({
	command = function(opts)
		opts = opts or {}
		local TmuxSessions = require("telescope-tmux.core.sessions"):new(opts)
		local TmuxState = require("telescope-tmux.core.tmux-state"):new()
		local utils = require("telescope-tmux.lib.utils")

		if
			utils.notified_user_about_session(
				opts,
				"Not in a Tmux session, session switch is not possible",
				vim.log.levels.ERROR
			)
		then
			return
		end

		TmuxSessions:switch_to_previous_session()
	end,
})
