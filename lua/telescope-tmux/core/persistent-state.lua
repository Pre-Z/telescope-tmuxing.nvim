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
