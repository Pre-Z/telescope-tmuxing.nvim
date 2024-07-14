local actions = require("telescope-tmux.pickers.windows.switch_window.actions")

return {
  ["<cr>"] = { cb = actions.on_select, desc = "switch_window" },
  ["<c-k>"] = { cb = actions.kill_window, desc = "kill_window" },
  ["<c-e>"] = { cb = actions.rename_window, desc = "rename_window" },
}
