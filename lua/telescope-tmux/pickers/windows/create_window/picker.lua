local TmuxPicker = require("telescope-tmux.core.base-picker")
local finder = require("telescope-tmux.pickers.windows.create_window.finder")
local mappings = require("telescope-tmux.pickers.windows.create_window.mappings")
local previewer = require("telescope-tmux.pickers.windows.create_window.previewer")
local sorters = require("telescope.sorters")

return TmuxPicker:new({
  title = "Create Window On Path",
  finder = finder,
  sorter = sorters.get_generic_fuzzy_sorter(),
  previewer = previewer,
  mappings = mappings,
})
