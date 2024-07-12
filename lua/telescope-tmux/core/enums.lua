local M = {}

M.common = {}
---@enum CommonSortingMethods -- this should be maintained based on the supported session and window SortBy values
M.common.sorting = {
  reverse_ordering_property = { -- the last used should be the first in the list
    property_match_pattern = "last_used",
    cut_pattern_for_value = nil,
  },
  string = {
    property_match_pattern = "name",
    cut_pattern_for_value = nil,
  },
  number = {
    property_match_pattern = ".+id",
    cut_pattern_for_value = "^[@$]",
  }
}

setmetatable(M.common.sorting, {
  __index = function(_, key)
    error("Invalid sorting key: " .. tostring(key))
  end
})

M.session = {}

---@enum SessionsSortBy
M.session.sorting = {
  usage = "last_used",
  name = "session_name",
  id = "session_id",
}

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

---@enum WindowsSortBy
M.window.sorting = {
  usage = "last_used",
  name = "window_name",
  id = "window_id",
}

---@enum WindowPreviewerName
M.window.listing.previewer_name = "telescope_tmuxing_window_previewer"

return M
