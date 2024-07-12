local actions = require("telescope-tmux.pickers.windows.switch_window.actions")

return {
  ["<cr>"] = actions.on_select,
  ["<c-k>"] = actions.kill_window,
  ["<c-r>"] = actions.rename_window,
}
