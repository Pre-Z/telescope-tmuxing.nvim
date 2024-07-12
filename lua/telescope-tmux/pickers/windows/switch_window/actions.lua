local action_state = require("telescope.actions.state")
local actions = require("telescope.actions")
-- local enum = require("telescope-tmux.core.enums")
local finder = require("telescope-tmux.pickers.windows.switch_window.finder")
local popup = require("telescope-tmux.lib.popup")
local utils = require("telescope-tmux.lib.utils")

local SwitchActions = {}

---@param prompt_bufnr number
---@param opts table
SwitchActions.on_select = function(prompt_bufnr, opts)
  if
    not utils.notified_user_about_not_in_tmux_session(
      opts,
      "Not in a Tmux session, window switch is not possible",
      vim.log.levels.ERROR
    )
  then
    local TmuxWindows = require("telescope-tmux.core.windows"):new(opts)
    local selection = action_state.get_selected_entry()
    local err = TmuxWindows:switch_window(selection.value.session_id, selection.value.window_id)
    if err ~= nil then
      local notifier = utils.get_notifier(opts)
      notifier(err, vim.log.levels.ERROR)
      return
    end
  end
  actions.close(prompt_bufnr)
end




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



SwitchActions.rename_window = function(prompt_bufnr, opts)
  local selection = action_state.get_selected_entry()
  local rename_callback = function(new_name)
    if not new_name then
      return
    end
    local TmuxWindows = require("telescope-tmux.core.windows"):new(opts)
    local err = TmuxWindows:rename_window(selection.value.session_id, selection.value.window_id, new_name)
    if err then
      local notifier = utils.get_notifier(opts)
      notifier("Failed to rename window: " .. err, vim.log.levels.ERROR)
    end

    utils.close_telescope_or_refresh(opts, prompt_bufnr, finder)
  end

  popup.show_input({
    prompt = "New name:",
    default = selection.value.window_name,
  }, rename_callback)
end

-- SwitchActions.kill_session = function(prompt_bufnr, opts)
--   local selection = action_state.get_selected_entry().value
--   local current_picker = action_state.get_current_picker(prompt_bufnr)
--   local multi_selection = current_picker:get_multi_selection()
--   local kill_cb_map = {
--     session = {},
--     window = {},
--   }
--
--   local pre_prompt = "Kill the selected (+ prefixed)\n"
--   local prompt = pre_prompt .. "sessions? [y/N]"
--   if #multi_selection > 0 then
--     for _, data in pairs(multi_selection) do
--       local session_data = data.value
--       if session_data.kind == enum.session.entity.kind.sub then
--         local parent_session_in_remove = false
--         for _, session in pairs(kill_cb_map.session) do
--           if session_data.session_id == session.session_id then
--             parent_session_in_remove = true
--             break
--           end
--         end
--         -- only add window if the parent session is not in the remove
--         if not parent_session_in_remove then
--           table.insert(kill_cb_map.window, session_data)
--         end
--       else
--         table.insert(kill_cb_map.session, session_data)
--       end
--     end
--     if #kill_cb_map.session > 1 and #kill_cb_map.window > 1 then
--       prompt = pre_prompt .. "sessions & windows? [y/N]"
--     elseif #kill_cb_map.session == 1 and #kill_cb_map.window == 1 then
--       prompt = pre_prompt .. "session & window? [y/N]"
--     elseif #kill_cb_map.session == 1 and #kill_cb_map.window > 1 then
--       prompt = pre_prompt .. "session & windows? [y/N]"
--     elseif #kill_cb_map.session > 1 and #kill_cb_map.window == 1 then
--       prompt = pre_prompt .. "sessions & window? [y/N]"
--     elseif #kill_cb_map.session == 0 then
--       prompt = pre_prompt .. "windows? [y/N]"
--     end
--   else
--     local type = "session"
--     if selection.kind == enum.session.entity.kind.sub then
--       type = "window"
--     end
--
--     kill_cb_map[type] = { selection }
--
--     prompt = string.format("Kill the selected %s? [y/N]", type)
--   end
--
--   local kill_cb = function(answer)
--     local accept_as_yes = { "yes", "Yes", "y", "Y", "YES", "yep" }
--     if not vim.tbl_contains(accept_as_yes, answer) then
--       return
--     end
--
--     local notifier = utils.get_notifier(opts)
--     if #kill_cb_map.session > 0 then
--       local TmuxSessions = require("telescope-tmux.core.sessions"):new(opts)
--
--       for _, session in pairs(kill_cb_map.session) do
--         local err = TmuxSessions:kill_session(session.session_id)
--         if err then
--           notifier("Failed to kill session: " .. err, vim.log.levels.ERROR)
--         end
--       end
--     end
--
--     -- do the window kill here
--
--     utils.close_telescope_or_refresh(opts, prompt_bufnr, finder)
--   end
--
--   popup.show_input({ prompt = prompt }, kill_cb)
-- end

return SwitchActions
