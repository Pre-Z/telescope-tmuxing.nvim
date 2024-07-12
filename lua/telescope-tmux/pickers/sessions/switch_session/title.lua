local config = require("telescope-tmux.core.config")
local enum = require("telescope-tmux.core.enums")

return function(opts)
  local conf = config.reinit_config(opts).opts

  return enum.session.listing.title[conf.list_sessions]
end
