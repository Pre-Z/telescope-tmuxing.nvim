local config = require("telescope-tmux.core.config")
local helper = require("telescope-tmux.lib.helper")
local previewers = require("telescope.previewers")

return function(opts)
  local conf = config.reinit_config(opts).opts

  return previewers.new_termopen_previewer({
    get_command = function(entry, _)
      local command = helper.shallow_copy_table(conf.create_session.previewer_command)
      table.insert(command, entry.value)
      return command
    end,
  })
end
