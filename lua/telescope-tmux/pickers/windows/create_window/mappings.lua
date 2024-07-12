local actions = require("telescope-tmux.pickers.windows.create_window.actions")

return {
	["<cr>"] = actions.on_select,
}

