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
end

return M
