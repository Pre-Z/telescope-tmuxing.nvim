local finders = require("telescope.finders")
local utils = require("telescope-tmux.lib.utils")

return function(opts)
  local TmuxWindows = require("telescope-tmux.core.windows"):new(opts)
  local TmuxState = require("telescope-tmux.core.tmux-state"):new(opts)

  utils.notified_user_about_not_in_tmux_session(
    opts,
    "Not in a Tmux session, window switch is not possible",
    vim.log.levels.ERROR
  )

  local current_session_id = TmuxState:get_session_id()
  local results = TmuxWindows:list_windows_of_session_id(current_session_id)

  local decide_if_valid = function(item)
    -- if not in tmux state do not exclude any session
    if not TmuxState:in_tmux_session() then
      return true
    end

    -- do not show the active window
    return not item.active_window
  end

  return finders.new_table({
    results = results,
    entry_maker = function(item)
      return {
        value = item,
        display = item.display,
        ordinal = item.ordinal and item.ordinal or item.window_name,
        valid = decide_if_valid(item),
      }
    end,
  })
end
