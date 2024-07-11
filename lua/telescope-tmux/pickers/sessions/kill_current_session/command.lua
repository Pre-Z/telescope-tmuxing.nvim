local TmuxCommand = require("telescope-tmux.core.base-command")
local popup = require("telescope-tmux.lib.popup")

---@class KillCurrentSessionCommand : TmuxCommand
local KillCurrentSessionCommand = TmuxCommand:new()
KillCurrentSessionCommand.__index = KillCurrentSessionCommand

return KillCurrentSessionCommand:new({
	command = function(opts)
		opts = opts or {}
		local TmuxSessions = require("telescope-tmux.core.sessions"):new(opts)
		local TmuxState = require("telescope-tmux.core.tmux-state"):new(opts)
		local utils = require("telescope-tmux.lib.utils")

		if utils.notified_user_about_not_in_tmux_session(opts, "Not in a Tmux session, nothing to kill", vim.log.levels.ERROR) then
			return
		end

		local notifier = utils.get_notifier(opts)
		local current_session_id = TmuxState:get_session_id()
		local switch_and_kill_cb = function()
			local previous_session = TmuxSessions:get_previous_session()
			if not previous_session then
				notifier("No previous session to swtich to, simply quit nvim and leave Tmux", vim.log.levels.INFO)
				return
			end

			local err = TmuxSessions:switch_to_session_and_kill_current(previous_session.session_id)
			if err then
				notifier("Failed to switch to previous session and kill current: " .. err, vim.log.levels.ERROR)
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
			prompt = "Kill current session? Select or Esc to abort",
		}
		popup.show_selector(select_table, selector_config)
	end,
})
