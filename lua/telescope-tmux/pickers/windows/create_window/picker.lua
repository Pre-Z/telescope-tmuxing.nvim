local TmuxPicker = require("telescope-tmux.core.base-picker")
local sorters = require("telescope.sorters")
local previewer = require("telescope-tmux.pickers.windows.create_window.previewer")
local finder = require("telescope-tmux.pickers.windows.create_window.finder")
local mappings = require("telescope-tmux.pickers.windows.create_window.mappings")

return TmuxPicker:new(
    {
    title = "Create Window On Path",
    finder = finder,
    sorter = sorters.get_generic_fuzzy_sorter(),
    previewer = previewer,
    mappings = mappings,
  }
)

