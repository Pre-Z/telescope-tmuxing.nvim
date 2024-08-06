local M = {}

local __default_key_sorter = function(tbl)
  local keys = {}
  for k in pairs(tbl) do
    table.insert(keys, k)
  end
  table.sort(keys)
  return keys
end

local sorter = __default_key_sorter

local __get_next_ordered_pairs = function(tbl, state) -- state is the last returned key from the table
  local key = nil

  if state == nil then
    tbl.__orderedKeys = sorter(tbl)
    key = tbl.__orderedKeys[1] -- get the first index
  else
    for key_array_position, key_value in pairs(tbl.__orderedKeys) do
      if key_value == state then
        key = tbl.__orderedKeys[key_array_position + 1]
      end
    end
  end

  if key then
    return key, tbl[key]
  end

  -- getting here means we do not have any more items to iterate, so cleanup and finish
  tbl.__orderedKeys = nil
  return nil
end

local __get_sorter_iterator = function(sorter_function)
  if sorter_function ~= nil and type(sorter_function) == "function" then
    sorter = sorter_function
  end

  return __get_next_ordered_pairs
end

M.reverse_sort_table = function(tbl)
  local keys = {}
  for k in pairs(tbl) do
    table.insert(keys, k)
  end
  table.sort(keys, function(a, b)
    return a > b
  end)
end

M.shallow_copy_table = function(orig)
  local orig_type = type(orig)
  local copy
  if orig_type == "table" then
    copy = {}
    for orig_key, orig_value in pairs(orig) do
      copy[orig_key] = orig_value
    end
  else -- number, string, boolean, etc
    copy = orig
  end
  return copy
end

M.concat_simple_lists = function(t1, t2)
  local tbl = M.shallow_copy_table(t1)
  for _, v in pairs(t2) do
    table.insert(tbl, v)
  end

  return tbl
end

---@param tbl table
---@param sorter_function function?
M.key_ordered_pairs = function(tbl, sorter_function)
  return __get_sorter_iterator(sorter_function), tbl, nil
end

M.cut_off_pattern_from_string = function(s, pattern)
  if not pattern then
    return s
  end

  return string.gsub(s, pattern, "")
end

M.get_last_folder_name_on_path = function(path)
  local folder_name = nil
  for last_folder_name in string.gmatch(path, "([^/]+)$") do -- get the last folder
    folder_name = last_folder_name
  end

  return folder_name
end

return M
