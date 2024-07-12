local TmuxCommand = require("telescope-tmux.core.base-command")
local popup = require("telescope-tmux.lib.popup")

---@class RenameCurrenWindowCommand : TmuxCommand
local RenameCurrentSessionCommand = TmuxCommand:new()
RenameCurrentSessionCommand.__index = RenameCurrentSessionCommand

return RenameCurrentSessionCommand:new({
  command = function(opts)
    opts = opts or {}
    local TmuxSessions = require("telescope-tmux.core.sessions"):new(opts)
    local TmuxState = require("telescope-tmux.core.tmux-state"):new(opts)
    local utils = require("telescope-tmux.lib.utils")

    if
      utils.notified_user_about_not_in_tmux_session(
        opts,
        "Not in a Tmux session, nothing to rename",
        vim.log.levels.ERROR
      )
    then
      return
    end

    local current_session_id = TmuxState:get_session_id()
    local rename_callback = function(new_name)
      if not new_name then
        return
      end

      local err = TmuxSessions:rename_session(current_session_id, new_name)
      if err then
        local notifier = utils.get_notifier(opts)
        notifier("Failed to rename session: " .. err, vim.log.levels.ERROR)
      end
    end

    local data = TmuxSessions:get_session_data_by_id(current_session_id)
    local current_name = data.session_name

    popup.show_input_center({
      prompt = "Rename current session to:",
      default = current_name,
    }, rename_callback)
  end,
})
