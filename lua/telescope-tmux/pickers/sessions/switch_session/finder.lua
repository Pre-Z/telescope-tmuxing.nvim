local finders = require("telescope.finders")
local config = require("telescope-tmux.core.config")

return function(opts)
	local TmuxSessions = require("telescope-tmux.core.sessions"):new(config.reinit_config(opts))
	local TmuxState = require("telescope-tmux.core.tmux-state"):new()
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
