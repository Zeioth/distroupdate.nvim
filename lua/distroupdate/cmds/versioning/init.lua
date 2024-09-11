--- ## Versioning functions
--
--  DESCRIPTION:
--  Functions used by the versioning commands of distroupdate.nvim

--    Functions:
--      -> freeze_plugin_versions   → used by :DistroFreezePluginVersions.
--      -> notify_version           → used by :DistroReadVersion.
--      -> print_changelog          → used by :DistroReadChangeLog.
--      -> create_rollback_file     → called automatically on :DistroUpdate.
--      -> rollback                 → used by :DistroUpdateRevert.

local utils = require("distroupdate.utils")
local git = require("distroupdate.utils.git")
local versioning = require("distroupdate.cmds.versioning.utils")

local M = {}


-- Helper function to generate a snapshot of the plugins currently installed.
function M.freeze_plugin_versions()
  local prev_snapshot = versioning.get_prev_snapshot_file()
  local plugins = versioning.get_plugins(prev_snapshot)
  versioning.write_new_snapshot(plugins)

  utils.notify("Lazy packages locked to their current version.")
end

--- Print the current distro version.
function M.notify_version()
  local version = git.current_version(false) or "unknown"
  if vim.g.distroupdate_config.branch == "nightly" then
    version = ("nightly (%s)"):format(version)
  end
  utils.notify("Version: " .. version)
end

--- Print the full distro changelog.
--- Unlike `updater.print_changelog()`, which only prints the update changes.
function M.print_changelog()
  local summary = {}
  vim.list_extend(summary, git.pretty_changelog(git.get_commit_range()))
  utils.echo(summary)
end

--- Create a rollback file that can be used by M.rollback() to revert the latest update.
--- @param write? boolean Whether or not to write to the rollback file (default: false)
--- @return table snapshot The written snapshot as table.
function M.create_rollback_file(write)
  -- create snapshot
  local snapshot = { branch = git.current_branch(), commit = git.local_head() }
  if snapshot.branch == "HEAD" then snapshot.branch = "main" end
  snapshot.remote = git.branch_remote(snapshot.branch, false) or "origin"
  snapshot.remotes = { [snapshot.remote] = git.remote_url(snapshot.remote) }

  -- write
  if write == true then
    local file = assert(io.open(vim.g.distroupdate_config.rollback_file, "w"))
    file:write(
      "return " .. vim.inspect(snapshot, { newline = " ", indent = "" })
    )
    file:close()
  end

  -- notify
  utils.notify(
    "Rollback file created in ~/.cache/nvim\n\npointing to commit:\n"
    .. snapshot.commit
    .. "  \n\nYou can use :DistroUpdateRevert to revert ~/.config to this state."
  )

  return snapshot
end

--- Distro rollback to the commit specified by the function `create_rollback`.
function M.rollback()
  local rollback_avail, rollback_opts =
      pcall(dofile, vim.g.distroupdate_config.rollback_file)
  if not rollback_avail then
    utils.notify("No rollback file available", vim.log.levels.ERROR)
    return
  end
  M.update(rollback_opts)
end

return M
