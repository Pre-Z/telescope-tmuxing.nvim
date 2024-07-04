local actions = require("telescope-tmux.pickers.sessions.switch_session.actions")

return {
	["<cr>"] = actions.on_select,
	["<c-d>"] = actions.delete_session,
	["<c-r>"] = actions.rename_session,
}
