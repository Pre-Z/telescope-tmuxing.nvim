local actions = require("telescope-tmux.pickers.windows.create_window.actions")

return {
  ["<cr>"] = { cb = actions.on_select, desc = "create_window" },
}
