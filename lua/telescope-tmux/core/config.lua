-- local utils = require("telescope-tmux.lib.utils")
local config = {}

---@class NvimNotifyOptions
---@field icon string
---@field title string
---@field timeout number milisecond

---@class TmuxConfig
---@field cache_folder string
---@field nvim_notify_options NvimNotifyOptions
---@field layout_strategy string
---@field sort_sessions "last_used" | "name"
local _TmuxDefaultConfig = {
  cache_folder = vim.api.nvim_call_function("stdpath", { "cache" }) .. "/telescope-tmux",
  sort_sessions = "last_used", -- possible options: "last_used", "name"
	nvim_notify_options = {
		icon = "﬿",
		title = "Telescope Tmux",
		timeout = 3000,
	},
	layout_strategy = "horizontal",
	layout_config = { preview_width = 0.8 },
}

config.setup = function(extension_config, telescope_config)
	config.opts = _TmuxDefaultConfig
	config.opts = vim.tbl_deep_extend("force", config.opts, telescope_config)
	config.opts = vim.tbl_deep_extend("force", config.opts, extension_config)
end

config.get_config = function ()
  return config.opts
end

config.reinit_config = function(opts)
	if opts ~= nil then
		config.opts = vim.tbl_deep_extend("keep", opts, config.opts)
	end
	return config
end

return config

