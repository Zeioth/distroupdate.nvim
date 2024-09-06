--- ## Versioning utils
--
--  DESCRIPTION:
--  Helpers used by the versioning commands of distroupdate.nvim

--  Functions:
--    -> get_previous_snapshot → return prev_snapshot as table.
--    -> get_plugins            → get the list of plugins to write.
--    -> write_new_snapshot     → write the plugin snapshot to the opened file.


local utils = require("distroupdate.utils")

local M = {}

--- Load the previous snapshot file as a Lua table and convert to a lookup table.
--- @param snapshot_filename string The name of the snapshot file.
--- @return table # A key pair table as { <plugin_name> = { ... }, }
function M.get_prev_snapshot_file()
  -- load the snapshot file as a Lua module (returns a table of plugins).
  local filename = vim.fn.fnamemodify(vim.g.distroupdate_config.snapshot_file, ':t:r')
  local prev_snapshot = require(filename) or {}

  -- convert the list of plugins into a lookup table, indexed by plugin name.
  for _, plugin in ipairs(prev_snapshot) do
    prev_snapshot[plugin[1]] = plugin -- Set plugin name as key.
  end

  -- return the lookup table for easy reference.
  return prev_snapshot
end

--- To the plugin data returned by lazy:
--- * Ovewrite plugin.commit with plugin dir git head (always).
--- * Overwrite plugin.version with prev_snapshot version (if present)
--- @param prev_snapshot table The previous snapshot.
--- @return table # The plugins returned by lazy, with our policies.
function M.get_plugins(prev_snapshot)
  local plugins = assert(require("lazy").plugins()) -- Retrieve all plugins.
  local n_invalid_plugins = 0

  -- Process them
  for _, plugin in ipairs(plugins) do

    -- 1. skip invalid plugins (the ones without an url)
    if not plugin[1] then
      n_invalid_plugins = n_invalid_plugins + 1
      goto continue
    end

    -- 2. get current local git head from plugin_dir.
    local plugin_dir_head = (function(plugin_dir)
      local cmd_result = assert(utils.cmd("git -C " .. plugin_dir .. " rev-parse HEAD", false))
      local commit_hash = cmd_result and vim.trim(cmd_result)
      return commit_hash
    end)(plugin.dir) -- lambda function

    -- 3. create a table with only the data we want.
    plugin = {
      plugin[1],                -- plugin name.
      version = plugin.version, -- plugin versin.
      commit = plugin_dir_head  -- plugin commit. (prevails over plugin.commit)
    }

    -- 4. if plugin has a version defined in prev_snapshot, it will prevail over plugin.version
    local prev_snapshot_has_version_field = prev_snapshot[plugin[1]] and prev_snapshot[plugin[1]].version
    if prev_snapshot_has_version_field then
      plugin.version = prev_snapshot[plugin[1]].version
    end

    ::continue::
  end

   if n_invalid_plugins > 0 then
    utils.notify(n_invalid_plugins .. " Plugins not added to the snapshot: No URL found.", vim.log.levels.WARN)
  end

  -- return the formatted plugin data.
  return plugins
end

--- Write the plugin snapshot to the file.
--- @param plugins table The list of valid plugins.
--- @return nil
function M.write_new_snapshot(plugins)
  local file = assert(io.open(vim.g.distroupdate_config.snapshot_file, "w"))

  -- start the Lua table structure in the file
  file:write "return {\n"

  -- loop through each plugin in the list of valid plugins.
  for _, plugin in ipairs(plugins) do
    -- write it.
    file:write(("  { %q, "):format(plugin[1])) -- Plugin name.
    if plugin.version then
      -- write the version if available.
      file:write(("version = %q "):format(plugin.version))
    else
      -- otherwise, write the commit hash.
      file:write(("commit = %q "):format(plugin.commit))
    end
    -- end the line in the file.
    file:write "},\n"
  end

  -- close the Lua table in the file.
  file:write "}\n"

  file:close()
end

return M
