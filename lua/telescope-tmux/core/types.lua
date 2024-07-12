---@class PersistentState
---@field get function
---@field write function
---@field cache_file string
---@field __notifier function

---@class TmuxWindowTable
---@field session_id string
---@field window_name string
---@field window_id string
---@field last_used number

---@class TmuxSessionTable
---@field session_id string
---@field session_name string
---@field last_used number
---@field windows table<string, TmuxWindowTable> -- windows by window_id
---@field window_list TmuxWindowTable[]

---@class TmuxSessionById<string, TmuxSessionTable>

---@class TmuxSessionDetails
---@field session_name string | nil
---@field windows table<string, string | nil> -- window_id => window_name

---@class TmuxState
---@field pstate PersistentState

---@class TmuxSessions
---@field sort_sessions_by string
---@field sort_windows_by string
---@field tstate TmuxState
---@field windows TmuxWindow
---@field __notifier function

---@class TmuxWindow
---@field sort_by SessionsListingOptions
---@field tstate TmuxState
---@field __notifier function

---@class NvimNotifyOptions
---@field icon string
---@field title string
---@field timeout number miliseconds

---@class CreateSessionOptions
---@field scan_paths string[]
---@field scan_pattern? string | string[] | function
---@field scan_depth number
---@field respect_gitignore boolean
---@field only_dirs boolean
---@field include_hidden_dirs boolean
---@field previewer_command string[]

---@class CreateWindowOptions
---@field scan_paths string[]
---@field scan_pattern? string | string[] | function
---@field include_cwd boolean
---@field scan_depth? number
---@field respect_gitignore boolean
---@field only_dirs boolean
---@field include_hidden_dirs boolean
---@field previewer_command string[]

---@class TmuxConfig
---@field cache_folder string
---@field nvim_notify NvimNotifyOptions
---@field layout_strategy string
---@field keep_telescope_open boolean
---@field list_sessions SessionsListingOptions
---@field sort_sessions SessionsSortBy
---@field sort_windows WindowsSortBy
---@field create_session CreateSessionOptions
---@field create_window CreateWindowOptions

---@class SessionLastUsedUpdateTable
---@field session_id string
---@field last_used number

---@class WindowLastUsedUpdateTable
---@field session_id string
---@field window_id string
---@field last_used number
