local config = require("telescope-tmux.core.config")
local utils = {}

---@param opts table -- the entire config table
utils.get_notifier = function(opts)
	local conf = config.reinit_config(opts).opts
	local notifier

	if conf.use_nvim_notify == nil or conf.use_nvim_notify then
		local notify_plugin_available, notify = pcall(require, "notify")
		if conf.use_nvim_notify and not notify_plugin_available then
			vim.notify(
				"Nvim-notify plugin is not available, but was set to be used, fallbacking to vim.notify. Please install nvim-notify to be able to use it.",
				vim.log.levels.ERROR
			)
		end
		local nvim_notify_wrapper = function(message, level)
			notify(message, level, conf.nvim_notify)
		end
		notifier = notify_plugin_available and nvim_notify_wrapper or vim.notify
	else
		notifier = vim.notify
	end

	return notifier
end

---@param opts table -- the entire config table
---@param message string
---@param log_level number
---@return boolean
utils.notified_user_about_session = function(opts, message, log_level)
	local notifier = utils.get_notifier(opts)
	local TmuxState = require("telescope-tmux.core.tmux-state"):new()

	if not TmuxState:in_tmux_session() then
		notifier(message, log_level)
		return true
	end

	return false
end

utils.close_telescope_or_refresh = function(opts, prompt_bufnr, finder)
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  local conf = config.reinit_config(opts).opts

	if conf.keep_telescope_open then
		local current_picker = action_state.get_current_picker(prompt_bufnr)
		current_picker:refresh(finder(opts))
	else
		actions.close(prompt_bufnr)
	end
end

---@param session_string string
---@return string | nil, string | nil, string | nil, string | nil
utils.get_tmux_session_data_parts = function(session_string)
	for session_id, session_name, window_id, window_name in
		string.gmatch(session_string, "([^:]*):([^:]*):([^:]*):([^:]*)")
	do
		return session_id, session_name, window_id, window_name
	end
end

---@param filename string
---@return boolean
utils.file_exists = function (filename)
    return vim.fn.filereadable(filename) == 1
end

return utils
