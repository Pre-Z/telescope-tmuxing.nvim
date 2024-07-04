local M = {}

---@class InputOptions
---@field prompt string
---@field default unknown

---@param opts InputOptions
---@param callback function
M.show_input = function(opts, callback)
	vim.ui.input(opts, callback)
end

return M
