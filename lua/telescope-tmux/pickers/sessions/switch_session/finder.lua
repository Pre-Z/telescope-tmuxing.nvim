local finders = require("telescope.finders")

return function(opts)
	local TmuxSessions = require("telescope-tmux.core.sessions"):new(opts)
	local TmuxState = require("telescope-tmux.core.tmux-state"):new()
	if not TmuxState:in_tmux_session() then
		local utils = require("telescope-tmux.lib.utils")
		local notifier = utils.get_notifier(opts)
		notifier("Not in a Tmux session, session switch is not possible", vim.log.levels.ERROR)
	end
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
