local previewers = require("telescope.previewers")
local tutils = require("telescope.utils")
local utils = require("telescope-tmux.lib.utils")
local M = {}

--- Gets buffer based Telescope Previewer
---@param base_index string
---@param previewer_session_name string -- the name of the previewer session being created to gain session:window preview
---@param value_property string -- selected item property to use for tmux command
---@return table
M.get_buffer_previewer = function(base_index, previewer_session_name, value_property)
  -- the main implementation for this is taken from https://github.com/camgraff/telescope-tmux.nvim/blob/cf857c1d28f6a5b0fd78ecb9d7c03fe95aa8eb3e/lua/telescope/_extensions/tmux/windows.lua
  return previewers.new_buffer_previewer({
    -- setup = function(_)
    --   vim.api.nvim_command(string.format("silent !tmux new-session -s %s -d", previewer_session_name))
    --   return {}
    -- end,
    define_preview = function(self, entry, _)
      -- if setup is used it seems that Telescope only sets the terminal once, so have to do it here and try to create session at every item
      vim.api.nvim_command(string.format("silent !tmux new-session -s %s -d", previewer_session_name))
      -- We have to set the window buf manually to avoid a race condition where we try to attach to
      -- the tmux sessions before the buffer has been set in the window. This is because Telescope
      -- calls nvim_win_set_buf inside vim.schedule()
      vim.api.nvim_win_set_buf(self.state.winid, self.state.bufnr)
      local window_id = entry.value[value_property]

      vim.api.nvim_buf_call(self.state.bufnr, function()
        -- kil the job running in previous previewer
        if tutils.job_is_running(self.state.termopen_id) then
          vim.fn.jobstop(self.state.termopen_id)
        end

        local target_window_id = previewer_session_name .. ":" .. base_index
        utils.link_tmux_window(window_id, target_window_id)

        self.state.termopen_id =
          vim.fn.termopen(string.format("tmux attach-session -t '%s' -r", previewer_session_name))
      end)
    end,
    teardown = function(_)
      vim.api.nvim_command(string.format("silent !tmux kill-session -t %s", previewer_session_name))
    end,
  })
end

--- Gets terminal based Telescope Previewer
---@param value_property string -- selected item property to use for tmux command
---@return table
M.get_terminal_previewer = function(value_property)
  return previewers.new_termopen_previewer({
    get_command = function(entry, _)
      return { "tmux", "attach-session", "-t", entry.value[value_property], "-r" }
    end,
  })
end

return M
