local TmuxCommand = require("telescope-tmux.core.base-command")
local popup = require("telescope-tmux.lib.popup")

---@class KillCurrentWindowCommand : TmuxCommand
local KillCurrentWindowCommand = TmuxCommand:new()
KillCurrentWindowCommand.__index = KillCurrentWindowCommand

return KillCurrentWindowCommand:new({
	command = function(opts)
		opts = opts or {}
		local TmuxWindows = require("telescope-tmux.core.windows"):new(opts)
		local TmuxState = require("telescope-tmux.core.tmux-state"):new(opts)
		local utils = require("telescope-tmux.lib.utils")

		if utils.notified_user_about_not_in_tmux_session(opts, "Not in a Tmux session, nothing to kill", vim.log.levels.ERROR) then
			return
		end

		local notifier = utils.get_notifier(opts)
    local current_window = TmuxState:get_current_window_data()
		local switch_and_kill_cb = function()
			local previous_window = TmuxWindows:get_previous_window()
			if not previous_window then
				notifier("No previous window to swtich to, simply quit nvim and leave Tmux", vim.log.levels.INFO)
				return
			end

      if not current_window then
        notifier("Failed to get information about the current window", vim.log.levels.ERROR)
        return
      end

			local err = TmuxWindows:switch_to_window_and_kill_current(previous_window, current_window)
			if err then
				notifier("Failed to switch to previous window and kill current: " .. err, vim.log.levels.ERROR)
			end
		end

		local save_session_then_switch_and_kill_cb = function()
			vim.cmd("wa")
			switch_and_kill_cb()
		end

		local select_table = {
			[1] = { ["Kill without saving changes"] = switch_and_kill_cb },
			[2] = { ["Save changes and kill"] = save_session_then_switch_and_kill_cb },
		}
		local selector_config = {
			prompt = "Kill current window? Select or Esc to abort",
		}
		popup.show_selector(select_table, selector_config)
	end,
})
