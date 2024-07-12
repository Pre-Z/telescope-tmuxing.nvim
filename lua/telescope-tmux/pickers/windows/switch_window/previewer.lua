local config = require("telescope-tmux.core.config")
local enum = require("telescope-tmux.core.enums")
local previewers = require("telescope-tmux.core.base-previewers")

return function(opts)
  local conf = config.reinit_config(opts).opts
  local TmuxState = require("telescope-tmux.core.tmux-state"):new(opts)
  local base_index = TmuxState:get_base_index()

  return previewers.get_buffer_previewer(base_index, enum.window.listing.previewer_name, "window_id")
end
