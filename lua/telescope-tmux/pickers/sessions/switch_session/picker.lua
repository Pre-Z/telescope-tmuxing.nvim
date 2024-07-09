local finder = require("telescope-tmux.pickers.sessions.switch_session.finder")
local sorters = require("telescope.sorters")
local previewer = require("telescope-tmux.pickers.sessions.switch_session.previewer")
local mappings = require("telescope-tmux.pickers.sessions.switch_session.mappings")
local TmuxPicker = require("telescope-tmux.core.base-picker")
local title = require("telescope-tmux.pickers.sessions.switch_session.title")

return TmuxPicker:new({
	title = title,
	finder = finder,
	sorter = sorters.get_generic_fuzzy_sorter(),
	previewer = previewer,
	mappings = mappings,
})
