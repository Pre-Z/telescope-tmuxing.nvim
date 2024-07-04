-- local utils = require("telescope-tmux.lib.utils")
local config = {}
local helper = require("telescope-tmux.lib.helper")

local __session_sort_possible_values = {
	"last_used",
	"name",
}

---@class NvimNotifyOptions
---@field icon string
---@field title string
---@field timeout number miliseconds

---@class CreateSessionOptions
---@field scan_paths string[]
---@field scan_pattern? string | string[] | function
---@field scan_depth number
---@field respect_gitignore boolean
---@field only_dirs boolean
---@field include_hidden_dirs boolean
---@field previewer_command string[]

---@class TmuxConfig
---@field cache_folder string
---@field nvim_notify NvimNotifyOptions
---@field layout_strategy string
---@field sort_sessions "last_used" | "name"
---@field keep_telescope_win_open boolean
---@field create_session CreateSessionOptions
local __TmuxDefaultConfig = {
	cache_folder = vim.api.nvim_call_function("stdpath", { "cache" }) .. "/telescope-tmux",
	sort_sessions = "last_used", -- possible options: "last_used", "name"
  keep_telescope_open = true, -- after quick actions (e.g. deleting/renaming session) keep telescope window open
	create_session = { -- plenary configuration options
    scan_paths = { "." },
    scan_pattern = nil,
    scan_depth = 1,
    respect_gitignore = true,
    include_hidden_dirs = false,
    only_dirs = true,
    previewer_command = { "ls", "-la", }
	},
	nvim_notify = {
		icon = "﬿",
		title = "Telescope Tmux",
		timeout = 3000,
	},
	layout_strategy = "horizontal",
	layout_config = { preview_width = 0.8 },
}

config.validate_config = function()
	if not vim.tbl_contains(__session_sort_possible_values, config.opts.sort_sessions) then
		error(
			"Telescope-Tmux: Invalid 'sort_sessions' option was given with value: " .. config.opts.sort_sessions,
			vim.log.levels.ERROR
		)
	end
end

config.setup = function(extension_config, telescope_config)
	extension_config = extension_config or {}
	telescope_config = telescope_config or {}
	config.opts = __TmuxDefaultConfig
	config = vim.tbl_deep_extend("force", config, telescope_config)
	config.opts = vim.tbl_deep_extend("force", config.opts, extension_config)

	config.validate_config()
end

config.get_config = function()
	return config.opts
end

config.reinit_config = function(opts)
	if config.opts == nil then
		config.opts = __TmuxDefaultConfig
	end

	if opts ~= nil then
		config.opts = vim.tbl_deep_extend("keep", opts, config.opts)
	end

	config.validate_config()
	return config
end

return config
