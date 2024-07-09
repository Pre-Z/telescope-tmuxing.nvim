local M = {}

M.session = {}

---@enum SessionOrderTypes
M.session.order = {
  usage = "last_used",
  default_name = "session_name",
}

---@enum SessionListingOptions
M.session.listing = {
  simple = "only_sessions",
  advanced = "with_windows",
}

return M
