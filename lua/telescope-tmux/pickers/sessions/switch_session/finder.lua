local finders = require("telescope.finders")
local utils = require("telescope-tmux.lib.utils")

return function(opts)
	local TmuxSessions = require("telescope-tmux.core.sessions"):new(opts)
	local TmuxState = require("telescope-tmux.core.tmux-state"):new()

	utils.notified_user_about_session(
		opts,
		"Not in a Tmux session, session switch is not possible",
		vim.log.levels.ERROR
	)

	local results = TmuxSessions:list_sessions()

	return finders.new_table({
		results = results,
		entry_maker = function(item)
			return {
				value = item,
				display = item.name,
				ordinal = item.name,
				valid = item.id ~= TmuxState:get_session_id(), -- do not show the current session
			}
		end,
	})
end
