local TmuxCommand = require("telescope-tmux.core.base-command")

---@class SwtichCommand : TmuxCommand
local SwitchCommand = TmuxCommand:new()
SwitchCommand.__index = SwitchCommand

return SwitchCommand:new({
	command = function(opts)
		opts = opts or {}
		local TmuxSessions = require("telescope-tmux.core.sessions"):new(opts)
		local TmuxState = require("telescope-tmux.core.tmux-state"):new(opts)
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
