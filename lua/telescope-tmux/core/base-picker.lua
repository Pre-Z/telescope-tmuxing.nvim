local telescope_utils = require("telescope-tmux.core.telescope_utils")
-- local utils = require("telescope-tmux.lib.utils")
-- local tmux_commands = require("telescope-tmux.core.tmux_commands")
local pickers = require("telescope.pickers")

---@class TmuxPickerOptions
---@field title string
---@field finder function
---@field sorter function
---@field previewer table
---@field mappings table

---@class TmuxPicker
---@field title string
---@field finder function
---@field sorter function
---@field previewer table
---@field mappings table
local TmuxPicker = {}
TmuxPicker.__index = TmuxPicker

---@param opts TmuxPickerOptions
function TmuxPicker:new(opts)
  local obj = {}
  obj.title = opts.title
  obj.finder = opts.finder
  obj.sorter = opts.sorter
  obj.previewer = opts.previewer
  obj.mappings = opts.mappings
  -- TODO: place back this functionality
  -- self._in_tmux_session = tmux_commands.being_in_tmux_session()
  setmetatable(obj, self)
  return obj
end

function TmuxPicker:get_picker_for_telescope(opts)
  local picker_options = {
    prompt_title = self.title,
    finder = self.finder(opts),
    sorter = self.sorter,
    previewer = self.previewer,
    attach_mappings = telescope_utils.get_attach_mappings_fn(self.mappings, opts),
  }

  picker_options = vim.tbl_deep_extend("keep", picker_options, opts)
  local picker = pickers.new(picker_options)
  picker:find()
end

return TmuxPicker
