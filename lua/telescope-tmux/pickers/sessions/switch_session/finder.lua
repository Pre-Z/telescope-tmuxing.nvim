local finders = require("telescope.finders")
local enums = require("telescope-tmux.core.enums")
local utils = require("telescope-tmux.lib.utils")

return function(opts)
  local TmuxSessions = require("telescope-tmux.core.sessions"):new(opts)
  local TmuxState = require("telescope-tmux.core.tmux-state"):new(opts)

  utils.notified_user_about_not_in_tmux_session(
    opts,
    "Not in a Tmux session, session switch is not possible",
    vim.log.levels.ERROR
  )

  local results = TmuxSessions:list_sessions(opts)

  local decide_if_valid = function(item)
    -- if not in tmux state do not exclude any session
    if not TmuxState:in_tmux_session() then
      return true
    end

    -- do not show the current session
    return item.session_id ~= TmuxState:get_session_id() and item.session_name ~= enums.session.listing.previewer_name
  end

  return finders.new_table({
    results = results,
    entry_maker = function(item)
      return {
        value = item,
        display = item.display,
        ordinal = item.ordinal and item.ordinal or item.session_name,
        valid = decide_if_valid(item),
      }
    end,
  })
end
