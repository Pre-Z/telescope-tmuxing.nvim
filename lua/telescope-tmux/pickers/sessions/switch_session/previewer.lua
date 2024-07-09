local previewers = require("telescope.previewers")
local tutils = require("telescope.utils")

return previewers.new_buffer_previewer({
  -- the main implementation for this is taken from https://github.com/camgraff/telescope-tmux.nvim/blob/cf857c1d28f6a5b0fd78ecb9d7c03fe95aa8eb3e/lua/telescope/_extensions/tmux/windows.lua
	define_preview = function(self, entry, _)
		-- We have to set the window buf manually to avoid a race condition where we try to attach to
		-- the tmux sessions before the buffer has been set in the window. This is because Telescope
		-- calls nvim_win_set_buf inside vim.schedule()
		vim.api.nvim_win_set_buf(self.state.winid, self.state.bufnr)
		vim.api.nvim_buf_call(self.state.bufnr, function()
			-- kil the job running in previous previewer
			if tutils.job_is_running(self.state.termopen_id) then
				vim.fn.jobstop(self.state.termopen_id)
			end

			local session_id = entry.value.window_id and entry.value.session_id .. ":" .. entry.value.window_id
				or entry.value.session_id

			self.state.termopen_id = vim.fn.termopen(string.format("tmux attach-session -t '%s' -r", session_id))
		end)
	end,
})
