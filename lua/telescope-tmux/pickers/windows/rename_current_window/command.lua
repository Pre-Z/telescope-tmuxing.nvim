local TmuxCommand = require("telescope-tmux.core.base-command")
local popup = require("telescope-tmux.lib.popup")

---@class RenameCurrenWindowCommand : TmuxCommand
local RenameCurrentWindowCommand = TmuxCommand:new()
RenameCurrentWindowCommand.__index = RenameCurrentWindowCommand

return RenameCurrentWindowCommand:new({
	command = function(opts)
		local TmuxWindows = require("telescope-tmux.core.windows"):new(opts)
		local TmuxState = require("telescope-tmux.core.tmux-state"):new(opts)
		local utils = require("telescope-tmux.lib.utils")

		if
			utils.notified_user_about_not_in_tmux_session(opts, "Not in a Tmux session, nothing to rename", vim.log.levels.ERROR)
		then
			return
		end

    local current_session_id, current_window_detils = TmuxState:get_current_session_id_and_window_data()
		local rename_callback = function(new_name)
			if not new_name then
				return
			end

			local err = TmuxWindows:rename_window(current_session_id, current_window_detils.window_id, new_name)
			if err then
				local notifier = utils.get_notifier(opts)
				notifier("Failed to rename window: " .. err, vim.log.levels.ERROR)
			end
		end

		popup.show_input_center({
			prompt = "Rename current session to:",
      default = current_window_detils.window_name,
		}, rename_callback)
	end,
})

