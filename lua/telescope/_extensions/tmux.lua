local telescope = require("telescope")
local config = require("telescope-tmux.core.config")

-- for debugging purpose
function table_print(tt, indent, done)
	done = done or {}
	indent = indent or 0
	if type(tt) == "table" then
		local sb = {}
		for key, value in pairs(tt) do
			table.insert(sb, string.rep(" ", indent)) -- indent it
			if type(value) == "table" and not done[value] then
				done[value] = true
				table.insert(sb, key .. " = {\n")
				table.insert(sb, table_print(value, indent + 2, done))
				table.insert(sb, string.rep(" ", indent)) -- indent it
				table.insert(sb, "}\n")
			elseif "number" == type(key) then
				table.insert(sb, string.format('"%s"\n', tostring(value)))
			else
				table.insert(sb, string.format('%s = "%s"\n', tostring(key), tostring(value)))
			end
		end
		return table.concat(sb)
	else
		return tt .. "\n"
	end
end

table_to_string = function(tbl)
	if "nil" == type(tbl) then
		return tostring(nil)
	elseif "table" == type(tbl) then
		return table_print(tbl)
	elseif "string" == type(tbl) then
		return tbl
	else
		return tostring(tbl)
	end
end

local pickers = {
	switch_session = require("telescope-tmux.pickers.sessions.switch_session.picker"),
  switch_prev_session = require("telescope-tmux.pickers.sessions.switch_to_previous_session.command"),
  create_session = require("telescope-tmux.pickers.sessions.create_session.picker"),
  rename_current_session = require("telescope-tmux.pickers.sessions.rename_current_session.command")
}

return telescope.register_extension({
	setup = config.setup,
	exports = vim.tbl_map(
		---@param tmux_picker TmuxPicker
		function(tmux_picker)
			return function(opts)
				tmux_picker:get_picker_for_telescope(opts)
			end
		end,
		pickers
	),
})
