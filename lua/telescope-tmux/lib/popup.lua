local helper = require("telescope-tmux.lib.helper")
local M = {}

---@class InputOptions
---@field prompt string
---@field default unknown

---@param opts InputOptions
---@param callback function
M.show_input = function(opts, callback)
	vim.ui.input(opts, callback)
end

M.show_input_center = function(...)
	local dressing_available, dressing = pcall(require, "dressing")
	if dressing_available then
		dressing.setup({
			input = {
				relative = "win",
			},
		})
	end

	M.show_input(...)

	-- FIXME: need a proper solution for this
	if dressing_available then
		dressing.setup({
			input = {
				relative = "cursor",
			},
		})
	end
end

---@param select_table table<number, table<string, function>>
---@param config InputOptions
M.show_selector = function(select_table, config)
	local options = {}
	local option_cb_table = {}

	for _, option in helper.key_ordered_pairs(select_table) do
		for title, cb in pairs(option) do
			option_cb_table[title] = cb
			table.insert(options, title)
		end
	end

	vim.ui.select(options, config, function(selection)
		if not selection then
			return
		end

		return option_cb_table[selection]()
	end)
end

return M
