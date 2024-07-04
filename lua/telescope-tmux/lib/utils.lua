local config = require("telescope-tmux.core.config")
local utils = {}

---@param opts table -- the entire config table
utils.get_notifier = function (opts)
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
utils.notified_user_about_session = function (opts, message, log_level)
  local notifier = utils.get_notifier(opts)
  local TmuxState = require("telescope-tmux.core.tmux-state"):new()

	if not TmuxState:in_tmux_session() then
		notifier(message, log_level)
    return true
	end

  return false
end

return utils

