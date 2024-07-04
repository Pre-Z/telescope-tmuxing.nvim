local TmuxCommand = require("telescope-tmux.core.base-command")
local config = require("telescope-tmux.core.config")

return TmuxCommand:new(
  {
    command = function (opts)
      opts = opts or {}
      local conf = config.setup(opts)
      local TmuxSessions = require("telescope-tmux.core.sessions"):new(conf)
      TmuxSessions:switch_to_previous_session()
    end,
  }
)
