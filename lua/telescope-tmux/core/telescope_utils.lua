local telescope_actions = require("telescope.actions")

local telescope_utils = {}

-- implementation comes from https://github.com/lpoto/telescope-docker.nvim/blob/4219840291d9e3e64f6b8eefa11e8deb14357581/lua/telescope-docker/core/telescope_util.lua
function telescope_utils.get_attach_mappings_fn(keys, opts)
  return function(prompt_bufnr, map)
    for key, meta in pairs(keys or {}) do
      if key == "<CR>" then
        telescope_actions.select_default:replace(function()
          meta.cb(prompt_bufnr, opts)
        end)
      else
        local modes = { "n" }
        if key:sub(1, 1) == "<" then
          table.insert(modes, "i")
        end
        for _, mode in ipairs(modes) do
          map(mode, key, function()
            meta.cb(prompt_bufnr, opts)
          end, { desc = meta.desc })
        end
      end
    end
    return true
  end
end

return telescope_utils
