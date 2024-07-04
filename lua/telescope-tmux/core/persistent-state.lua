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

local persist = require("telescope-tmux.lib.persist")
local utils = require("telescope-tmux.lib.utils")
local config = require("telescope-tmux.core.config")

local prepare_cache_folder = function (config)
  -- prepare the cache folder
  if vim.fn.isdirectory(config.cache_folder) == 0 then
		vim.fn.mkdir(config.cache_folder, "p")
	end
end

---@class PersistentState
---@field get function
---@field write function
---@field cache_file string
---@field __notifier function
local PersistentState = {}
PersistentState.__index = PersistentState

---@param opts table
---@param cache_file string
function PersistentState:new(opts, cache_file)
  local obj = {}
  local conf = config.reinit_config(opts).opts

  -- TODO: clarify if this should be reinited or not
  obj.__notifier = utils.get_notifier(opts)
  obj.cache_file = conf.cache_folder .. "/" .. cache_file
  setmetatable(obj, self)
  prepare_cache_folder(conf)

  return obj
end

function PersistentState:get()
  local content, err = persist.load_table(self.cache_file)
  if err then
    self.__notifier("Failed to read cache file (" .. self.cache_file .. "): " .. err, vim.log.levels.error)
    return {}
  end
  return content
end

---@param content any
function PersistentState:write(content)
 local _, err = persist.save_table(content, self.cache_file)

  if err then
    self.__notifier("Error writing to file: " .. err, vim.log.levels.error)
  end
end

return PersistentState
