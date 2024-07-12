local TmuxPicker = require("telescope-tmux.core.base-picker")
local enums = require("telescope-tmux.core.enums")
local finder = require("telescope-tmux.pickers.windows.switch_window.finder")
local mappings = require("telescope-tmux.pickers.windows.switch_window.mappings")
local previewer = require("telescope-tmux.pickers.windows.switch_window.previewer")
local sorters = require("telescope.sorters")

return TmuxPicker:new({
  title = enums.window.listing.title,
  finder = finder,
  sorter = sorters.get_generic_fuzzy_sorter(),
  previewer = previewer,
  mappings = mappings,
})
