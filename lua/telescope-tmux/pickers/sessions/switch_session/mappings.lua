local actions = require("telescope-tmux.pickers.sessions.switch_session.actions")

return {
	["<cr>"] = actions.on_select,
}

