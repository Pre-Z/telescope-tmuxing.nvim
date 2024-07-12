local finder = require("telescope-tmux.pickers.windows.switch_window.finder")
local sorters = require("telescope.sorters")
local previewer = require("telescope-tmux.pickers.windows.switch_window.previewer")
local mappings = require("telescope-tmux.pickers.windows.switch_window.mappings")
local TmuxPicker = require("telescope-tmux.core.base-picker")
local enums = require("telescope-tmux.core.enums")

return TmuxPicker:new({
	title = enums.window.listing.title,
	finder = finder,
	sorter = sorters.get_generic_fuzzy_sorter(),
	previewer = previewer,
	mappings = mappings,
})
