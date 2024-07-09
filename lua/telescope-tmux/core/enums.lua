local M = {}

M.session = {}

---@enum SessionsOrderBy
M.session.order = {
  usage = "last_used",
  default_name = "session_name",
}

M.session.listing = {}

---@enum SessionsListingOptions
M.session.listing.type = {
  simple = "only_sessions",
  advanced = "with_windows",
}

M.session.listing.title = {
  [M.session.listing.type.simple] = "Other Active Tmux Sessions",
  [M.session.listing.type.advanced] = "Active Tmux Sessions & Windows",
}

return M
