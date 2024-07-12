local TmuxCommand = require("telescope-tmux.core.base-command")
local config = require("telescope-tmux.core.config")

---@class SwtichWindowCommand : TmuxCommand
local SwitchWindowCommand = TmuxCommand:new()
SwitchWindowCommand.__index = SwitchWindowCommand

return SwitchWindowCommand:new({
  command = function(opts)
    local utils = require("telescope-tmux.lib.utils")

    if
      utils.notified_user_about_not_in_tmux_session(
        opts,
        "Not in a Tmux session, window switch is not possible",
        vim.log.levels.ERROR
      )
    then
      return
    end
    local TmuxWindows = require("telescope-tmux.core.windows"):new(opts)
    local TmuxState = require("telescope-tmux.core.tmux-state"):new(opts)
    local conf = config.reinit_config(opts).opts
    local session = nil
    if not conf.cross_session_window_switch then
      session = TmuxState:get_current_session_data()
    end

    TmuxWindows:switch_to_previous_window(session)
  end,
})
