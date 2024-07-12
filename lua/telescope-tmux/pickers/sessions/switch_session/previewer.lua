local config = require("telescope-tmux.core.config")
local enum = require("telescope-tmux.core.enums")
local previewers = require("telescope-tmux.core.base-previewers")

return function(opts)
  local conf = config.reinit_config(opts).opts
  if conf.list_sessions == enum.session.listing.type.full then
    local TmuxState = require("telescope-tmux.core.tmux-state"):new(opts)

    local base_index = TmuxState:get_base_index()
    local previewer_session_name = "telescope_tmuxing_previewer_session"

    return previewers.get_buffer_previewer(base_index, previewer_session_name, "window_id")
  end

  return previewers.get_terminal_previewer("session_id")
end
