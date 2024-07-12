local TmuxPicker = require("telescope-tmux.core.base-picker")
local finder = require("telescope-tmux.pickers.sessions.create_session.finder")
local mappings = require("telescope-tmux.pickers.sessions.create_session.mappings")
local previewer = require("telescope-tmux.pickers.sessions.create_session.previewer")
local sorters = require("telescope.sorters")

return TmuxPicker:new({
  title = "Create Session On Path",
  finder = finder,
  sorter = sorters.get_generic_fuzzy_sorter(),
  previewer = previewer,
  mappings = mappings,
})
