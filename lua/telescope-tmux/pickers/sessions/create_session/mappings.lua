local actions = require("telescope-tmux.pickers.sessions.create_session.actions")

return {
  ["<cr>"] = actions.on_select,
}
