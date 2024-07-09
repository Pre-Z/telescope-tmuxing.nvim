---@class PersistentState
---@field get function
---@field write function
---@field cache_file string
---@field __notifier function

---@class TmuxWindowTable
---@field window_id string
---@field window_name string
---@field last_used number

---@class TmuxSessionTable
---@field session_id string
---@field sesssion_name string
---@field last_used number
---@field windows table<string, TmuxWindowTable> -- windows by window_id

---@class TmuxSessionDetails
---@field session_name string | nil
---@field windows table<string, string | nil> -- window_id => window_name

---@class TmuxState
---@field pstate PersistentState

---@class TmuxSessions
---@field sort_by string
---@field tstate TmuxState
---@field __notifier function

