local finders = require("telescope.finders")
local helper = require("telescope-tmux.lib.helper")

return function (opts)
  local plenary_available, scanner = pcall(require, 'plenary.scandir')
  local results = {}
  if not plenary_available then
    local utils = require("telescope-tmux.lib.utils")
    local notifier = utils.get_notifier(opts)

    -- throw a notification and leave results empty
    notifier("Missing required plugin ('pleanry.nvim') for tmux session create", vim.log.levels.ERROR)
  else
    local config = require("telescope-tmux.core.config")
    local conf = config.reinit_config(opts).opts.create_session
    local scanner_config = {}
    scanner_config.hidden = conf.include_hidden_dirs
    scanner_config.search = conf.scan_pattern
    scanner_config.depth = conf.scan_depth
    scanner_config.respect_gitignore = conf.respect_gitignore
    scanner_config.only_dirs = conf.only_dirs

    local dirs = {}
    for _, dir in pairs(conf.scan_paths) do
      dir = vim.fn.expand(dir) -- resolve ~/ path to full path otherwise scan_dir will say that the current user has no access to the directory
      dir = string.gsub(dir, "/$", "") -- cutting off the trailing / if there is any
      table.insert(dirs, dir)
    end

    local found_dirs = scanner.scan_dir(dirs, scanner_config) -- adding the parent directories also

    results = helper.concat_simple_lists(found_dirs, dirs)
    table.sort(results)
  end

  return finders.new_table({
		results = results,
		entry_maker = function(item)
			return {
				value = item,
        display = item,
        ordinal = item,
        valid = true,
			}
		end,
  })
end
