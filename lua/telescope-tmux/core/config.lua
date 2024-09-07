local config = {}
local enums = require("telescope-tmux.core.enums")

local __session_sort_possible_values = {
  enums.session.sorting.name,
  enums.session.sorting.id,
  enums.session.sorting.usage,
}

local __session_listing_possible_values = {
  enums.session.listing.type.full,
  enums.session.listing.type.simple,
}

---@type TmuxConfig
local __TmuxDefaultConfig = {
  cache_folder = vim.api.nvim_call_function("stdpath", { "state" }) .. "/telescope-tmuxing",
  sort_sessions = "last_used", -- possible options: "last_used", "session_name"
  list_sessions = "simple", -- options: "full", "simple"
  sort_windows = "last_used", -- possible options: "last_used", "session_name"
  keep_telescope_open = true, -- after quick actions (e.g. deleting/renaming session) keep telescope window open
  cross_session_window_switch = false, -- if true switch to previous session will consider all windows across all active sessions
  create_session = { -- this section configures Plenary directory scanner
    scan_paths = { "~/" }, -- string list of paths, ~/ means the user's home directory
    scan_pattern = nil, -- regex to filter out scan results
    scan_depth = 1,
    run_command = nil,
    respect_gitignore = true,
    include_hidden_dirs = false,
    only_dirs = true, -- not recommended to change to false, but if you have symlinks of directories it may be useful, but make sure you select only directories or their symlinks
    previewer_command = { "ls", "-la" },
  },
  create_window = { -- plenary configuration options
    scan_paths = {}, -- this can be empty if include_cwd is turned on; note if you have include_cwd on and you include "." or "./" in the scan_paths you will get the current directory and its subdirs twice
    include_cwd = true, -- will run vim.fn.getcwd() and will include it in scan_paths, this gives a good compatibility with neo-tree if you change the root path during your session
    scan_pattern = nil,
    scan_depth = nil,
    respect_gitignore = true,
    include_hidden_dirs = false,
    only_dirs = true,
    previewer_command = { "ls", "-la" },
  },
  nvim_notify = { -- configuration options for nvim_notify
    icon = "﬿",
    title = "Telescope Tmux",
    timeout = 3000,
  },
  layout_strategy = "horizontal",
  layout_config = { preview_width = 0.78 },
}

config.validate_config = function()
  if not vim.tbl_contains(__session_sort_possible_values, config.opts.sort_sessions) then
    local fallback_sorting_type = enums.sorting.usage
    error(
      "Telescope-Tmuxing: Invalid 'sort_sessions' option was given with value: "
        .. config.opts.sort_sessions
        .. ". Fallbacking to: '"
        .. fallback_sorting_type
        .. "'",
      vim.log.levels.ERROR
    )
  end

  if not vim.tbl_contains(__session_listing_possible_values, config.opts.list_sessions) then
    local simple_listing = enums.session.listing.type.simple
    config.opts.list_sessions = simple_listing -- defaulting to simple
    error(
      "Telescope-Tmuxing: Invalid session listing options was given: "
        .. config.opts.list_sessions
        .. ". Fallbacking to: '"
        .. simple_listing
        .. "' listing type",
      vim.log.levels.ERROR
    )
  end
end

config.setup = function(extension_config, telescope_config)
  extension_config = extension_config or {}
  telescope_config = telescope_config or {}
  config.opts = __TmuxDefaultConfig
  if telescope_config ~= nil then
    config = vim.tbl_deep_extend("force", config, telescope_config)
  end
  if extension_config ~= nil then
    config.opts = vim.tbl_deep_extend("force", config.opts, extension_config)
  end

  config.validate_config()
end

config.reinit_config = function(opts)
  if config.opts == nil then
    config.opts = __TmuxDefaultConfig
  end

  if opts ~= nil then
    if opts.opts ~= nil then
      config = vim.tbl_deep_extend("force", config, opts)
    else
      config.opts = vim.tbl_deep_extend("force", config.opts, opts)
    end
  end

  config.validate_config()
  return config
end

return config
