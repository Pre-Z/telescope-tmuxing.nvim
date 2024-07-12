local telescope = require("telescope")
local config = require("telescope-tmux.core.config")

local pickers = {
  -- Sessions
	switch_session = require("telescope-tmux.pickers.sessions.switch_session.picker"),
  switch_prev_session = require("telescope-tmux.pickers.sessions.switch_to_previous_session.command"),
  create_session = require("telescope-tmux.pickers.sessions.create_session.picker"),
  rename_current_session = require("telescope-tmux.pickers.sessions.rename_current_session.command"),
  kill_current_session = require("telescope-tmux.pickers.sessions.kill_current_session.command"),

  --- Windows
  switch_window = require("telescope-tmux.pickers.windows.switch_window.picker"),
  rename_current_window = require("telescope-tmux.pickers.windows.rename_current_window.command"),
  kill_current_window = require("telescope-tmux.pickers.windows.kill_current_window.command"),
  switch_prev_window = require("telescope-tmux.pickers.windows.switch_to_previous_window.command"),
}

return telescope.register_extension({
	setup = config.setup,
	exports = vim.tbl_map(
		---@param tmux_picker TmuxPicker
		function(tmux_picker)
			return function(opts)
				tmux_picker:get_picker_for_telescope(opts)
			end
		end,
		pickers
	),
})
