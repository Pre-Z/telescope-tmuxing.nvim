local M = {}

M.common = {}
---@enum CommonSortingMethods
M.common.sorting = {
  usage = "last_used",
  session_name = "session_name",
  window_name = "window_name",
}

M.session = {}

---@alias SessionsSortBy CommonSortingMethods
M.session.sorting = M.common.sorting

M.session.listing = {}

---@enum SessionsListingOptions
M.session.listing.type = {
  simple = "simple",
  full = "full",
}

M.session.listing.title = {
  simple = "Other Active Tmux Sessions",
  full = "Other Active Tmux Sessions & Windows",
}

---@enum SessionPreviewerName
M.session.listing.previewer_name = "telescope_tmuxing_session_previewer"

M.session.entity = {}

---@enum SessionEntityType
M.session.entity.kind = {
  main = "root",
  sub = "child",
}

M.window = {}
M.window.listing = {}

---@enum WindowListingTitle
M.window.listing.title = "Other Windows of Active Tmux Session"

---@alias WindowsSortBy CommonSortingMethods
M.window.sorting = M.common.sorting

---@enum WindowPreviewerName
M.window.listing.previewer_name = "telescope_tmuxing_window_previewer"

return M
