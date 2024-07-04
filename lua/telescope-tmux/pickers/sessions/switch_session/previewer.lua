local previewers = require("telescope.previewers")

return previewers.new_termopen_previewer({
	get_command = function(entry, _)
		return { "tmux", "attach-session", "-t", entry.value.id, "-r" }
	end,
})
