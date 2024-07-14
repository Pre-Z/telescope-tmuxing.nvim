local actions = require("telescope-tmux.pickers.sessions.switch_session.actions")

return {
  ["<cr>"] = { cb = actions.on_select, desc = "switch_session" },
  ["<c-k>"] = { cb = actions.kill_session, desc = "kill_session" },
  ["<c-e>"] = { cb = actions.rename_session, desc = "rename_session" },
}
