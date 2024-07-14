local actions = require("telescope-tmux.pickers.sessions.create_session.actions")

return {
  ["<cr>"] = { cb = actions.on_select, desc = "create_session" },
}
