local TmuxPicker = require("telescope-tmux.core.base-picker")
local finder = require("telescope-tmux.pickers.sessions.switch_session.finder")
local mappings = require("telescope-tmux.pickers.sessions.switch_session.mappings")
local previewer = require("telescope-tmux.pickers.sessions.switch_session.previewer")
local sorters = require("telescope.sorters")
local title = require("telescope-tmux.pickers.sessions.switch_session.title")

return TmuxPicker:new({
  title = title,
  finder = finder,
  sorter = sorters.get_generic_fuzzy_sorter(),
  previewer = previewer,
  mappings = mappings,
})
