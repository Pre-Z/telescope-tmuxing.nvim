local telescope = require("telescope")
local config = require("telescope-tmux.core.config")

local pickers = {
	switch_session = require("telescope-tmux.pickers.sessions.switch_session.picker"),
  switch_prev_session = require("telescope-tmux.pickers.sessions.switch_to_previous_session.command"),
  create_session = require("telescope-tmux.pickers.sessions.create_session.picker"),
  rename_current_session = require("telescope-tmux.pickers.sessions.rename_current_session.command"),
  kill_current_session = require("telescope-tmux.pickers.sessions.kill_current_session.command"),
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
