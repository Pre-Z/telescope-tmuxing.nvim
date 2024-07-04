return {
	["<cr>"] = function(prompt_bufnr)
		local actions = require("telescope.actions")
		local action_state = require("telescope.actions.state")
		local selection = action_state.get_selected_entry()
    local tutils = require("telescope.utils")
    local current_client = tutils.get_os_command_output({ "tmux", "display-message", "-p", "#{client_tty}" })[1]

      vim.cmd(string.format('silent !tmux switchc -t "%s" -c "%s"', selection.value, current_client))
		actions.close(prompt_bufnr)
	end,
	["<c-a>"] = custom_actions.create_new_session,
	["<c-d>"] = custom_actions.delete_session,
	["<c-r>"] = custom_actions.rename_session,
}
