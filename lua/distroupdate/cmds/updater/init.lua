--- ## Updater functions
--
--  DESCRIPTION:
--  Function used by the updater commands of distroupdate.nvim

--    Functions:
--      -> update              → used by :DistroUpdate.

local git = require("distroupdate.utils.git")
local updater = require("distroupdate.cmds.updater.utils")
local versioning = require("distroupdate.cmds.versioning")

local M = {}

--- Updates the distro.
--- @return boolean success Returns `true` if the process has completed without errors.
function M.update()
  -- pre-requisites
  if not updater.is_git_installed() then return false end
  if not updater.distro_is_git_repo() then return false end
  if not updater.fetch_from_remote() then return false end

  local git_head_commit = git.local_head()
  local git_target_commit = updater.get_target_commit()
  local changelog = git.get_commit_range(git_target_commit, git_head_commit)

  -- confirm
  if not updater.updates_available(git_head_commit, git_target_commit) then return false end
  if not updater.confirm_update(git_target_commit) then return false end
  if not updater.confirm_breaking_changes(changelog) then return false end

  -- update
  versioning.create_rollback_file(true)
  if not updater.git_checkout() then return false end
  if not updater.attempt_update(git_head_commit, git_target_commit) then return false end

  -- post update stuff
  updater.trigger_post_update_events()
  updater.print_changelog(changelog)

  return true
end

return M
