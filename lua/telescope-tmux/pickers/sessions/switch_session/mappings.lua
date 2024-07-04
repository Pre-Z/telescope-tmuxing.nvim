local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local utils = require("telescope-tmux.lib.utils")

return {
	["<cr>"] = function(prompt_bufnr, opts)
    local TmuxSessions = require("telescope-tmux.core.sessions"):new(opts)
    local selection = action_state.get_selected_entry()
    local err = TmuxSessions:switch_session(selection.value.id)
    if err ~= nil then
      local notifier = utils.get_notifier(opts)
      notifier(err, vim.log.levels.ERROR)
      return
    end
		actions.close(prompt_bufnr)
	end,
}

