--- ## Updater utils
--
--  DESCRIPTION:
--  Helper functions used by the updater.

--    Functions:
--      -> is_git_installed           → guard clause.
--      -> distro_is_git_repo         → guard clause.
--      -> fetch_from_remote          → download remote changes.
--      -> git_checkout               → checkout a branch.
--      -> get_target_commit          → commit to update to.
--      -> confirm_update             → prompt user.
--      -> confirm_breaking_changes   → prompt user.
--      -> attempt_update             → the actual update function.
--      -> print_changelog            → user feedback.
--      -> trigger_post_update_events → update and close nvim.

local utils = require("distroupdate.utils")
local git = require("distroupdate.utils.git")

local M = {}

--- Checks if git is installed on the computer.
--- @return boolean success returns `false` if git is not installed on the computer.
function M.is_git_installed()
  if not git.available() then
    utils.notify(
      "git command is not available, please verify it is accessible in a command line. This may be an issue with your PATH",
      vim.log.levels.ERROR
    )
    return false
  end

  -- If all guard clauses pass
  return true
end

--- Checks if the neovim config directory is a git repository.
--- @return boolean success returns `false` if the neovim config directory is not a git repository.
function M.distro_is_git_repo()
  if not git.is_repo() then
    utils.notify(
      "Updater not available for non-git installations",
      vim.log.levels.ERROR
    )
    return false
  end

  -- If all guard clauses pass
  return true
end

--- Display the current git remote. Then it does git fetch from the git remote specified in the config.
--- @return boolean success returns `false` if the operation is unsuccesful.
function M.fetch_from_remote()
  local config = vim.g.distroupdate_config
  local url = git.remote_url(config.remote, false)

  -- Print remote to use
  utils.echo({
    { "Git remote " },
    { config.remote,                 "Title" },
    { " currently set to " },
    { url,                           "WarningMsg" },
    { "..." },
  })

  -- fetch the latest remote
  local result_ok = git.fetch(config.remote)
  if not result_ok then
    vim.api.nvim_err_writeln("Error fetching from remote: " .. config.remote)
    return false
  end

  -- If all guard clauses pass
  return true
end

--- If necessary, download the branch from `config.remote` and perform `git checkout`.
--- @return boolean success returns `false` if the operation is unsuccesful.
function M.git_checkout()
  local config = vim.g.distroupdate_config

  -- Set remote branch
  local remote_branch_exists = git.ref_verify(config.remote .. "/" .. config.branch, false)
  if remote_branch_exists then git.remote_set_branches(config.remote, config.branch, false) end

  -- Set local branch
  local formatted_remote = (config.remote == "origin" and "" or (config.remote .. "_"))
  local formatted_remote_branch = formatted_remote .. config.branch

  -- Checkout to new branch (if necessary)
  local changing_to_new_branch = git.current_branch() ~= formatted_remote_branch
  if changing_to_new_branch then
    -- print branch to change to
    utils.echo {
      { "Switching to branch: " },
      { config.remote .. "/" .. config.branch .. "\n\n", "String" },
    }

    -- reset uncommited changes to ensure checkout doesn't fail. (current branch)
    -- (alternatively, we could stash)
    if config.ovewrite_uncommited_local_changes then
      git.hard_reset(git.local_head())
    end

    -- do checkout
    local result_ok = git.checkout(formatted_remote_branch, false)
    if not result_ok then
      -- branch doesn't exists locally; create it from remote.
      git.checkout(
        "-b " .. formatted_remote_branch .. " " .. config.remote .. "/" .. config.branch,
        false
      )
    end

    -- print error if any
    local error = git.current_branch() ~= formatted_remote_branch
    if error then vim.api.nvim_err_writeln(
        "Error checking out branch: " .. config.remote .. "/" .. config.branch)
      return false
    end
  end

  -- If all guard clauses pass
  return true
end

--- Get the commit hash the updater is going to update the distro to.
--- @return string|nil commit a commit hash.
function M.get_target_commit()
  local config = vim.g.distroupdate_config

  -- There are 3 exclusive scenarios:
  -- 1. commit is specified.
  if config.commit then
    local git_target_commit = git.branch_contains(config.remote, config.branch, config.commit)
        and config.commit
        or nil
    return git_target_commit
  end

  -- 2. channel is stable.
  if config.branch == "main" then -- get the specified version
    local target_version = git.latest_version(git.get_versions(config.release_tag))
    if not target_version then
      vim.api.nvim_err_writeln("Error finding version: " .. config.release_tag)
      return nil
    end
    local git_target_commit = git.tag_commit(target_version)
    return git_target_commit
  end

  -- 3. channel is nightly/other
  if config.branch ~= "main" then -- get most recent commit
    local most_recent_commit = git.remote_head(config.remote, config.branch)
    local git_target_commit = most_recent_commit
    return git_target_commit
  end
end

--- Returns a boolean value indicating if there are updates available.
--- @param git_head_commit string|nil Old git head commit.
--- @param git_target_commit string|nil The commit that is going to be the new git head after the update.
--- @return boolean success returns `false` if there are no updates available.
function M.updates_available(git_head_commit, git_target_commit)
  if not git_head_commit or not git_target_commit then
    vim.api.nvim_err_writeln("Error checking for updates")
    return false
  end

  if git_head_commit == git_target_commit then
    utils.echo { { "No changes available", "String" } }
    return false
  end

  -- If all guard clauses pass
  return true
end

--- Prompt the user to confirm the update.
--- @param git_target_commit string|nil The commit that is going to be the new git head after the update.
--- @return boolean success If `false`, it means the user canceled the update.
function M.confirm_update(git_target_commit)
  local config = vim.g.distroupdate_config
  local version = git.latest_version(git.get_versions(config.release_tag))

  local update_canceled = not config.auto_accept_prompts
      and not utils.confirm_prompt(
        ("Update avavilable to %s\nUpdating requires a restart, continue?"):format(
          config.branch == "main" and version or git_target_commit
        )
      )
  if update_canceled then
    utils.echo({ { "Update cancelled", "WarningMsg" } })
    return false
  else
    return true
  end
end

--- Prompt the user to confirm the update.
--- @param changelog string[] A table returned by the function `git.get_commit_range()`.
--- @return boolean success If `false`, it means the user canceled the update.
function M.confirm_breaking_changes(changelog)
  local config = vim.g.distroupdate_config

  local breaking = git.breaking_changes(changelog)
  local update_canceled = #breaking > 0
      and not config.auto_accept_prompts
      and not utils.confirm_prompt(
        ("It contains the following breaking changes:\n%s\n\nWould you like to continue?"):format(
          table.concat(breaking, "\n")
        ), "WarningMsg"
      )

  if update_canceled then
    utils.echo({ { "Update cancelled", "WarningMsg" } })
    return false
  end

  -- If all guard clauses pass
  return true
end

--- Attempt an update of the distro.
--- @param git_head_commit string|nil Old git head commit.
--- @param git_target_commit string|nil The commit that is going to be the new git head after the update.
--- @return boolean success If `false`, it means the update has failed.
function M.attempt_update(git_head_commit, git_target_commit)
  local config = vim.g.distroupdate_config
  local result = nil

  -- reset uncommited changes to ensure checkout doesn't fail. (target branch)
  if config.ovewrite_uncommited_local_changes and git_head_commit then
    git.hard_reset(git_head_commit)
  end

  if config.branch == "main" and git_target_commit then
    -- for sable versions, checkout target commit.
    result = git.checkout(git_target_commit, false)
  else
    -- for nightly/other, pull the latest changes from the current branch.
    result = git.pull(false)
  end

  if not result then
    vim.api.nvim_err_writeln("Error occurred performing update")
    return false
  end

  -- If all guard clauses pass
  return true
end

--- Prints the changelog passed as parameter in the specified format.
---
--- Note: be aware lazy update will close the changelog, so you might want
---       to run this function afterwards.
--- @param changelog string[] A table returned by the function `git.get_commit_range()`.
function M.print_changelog(changelog)
  local config = vim.g.distroupdate_config

  -- print a summary of the update with the changelog
  local summary = {
    { "Neovim updated successfully to ", "Title" },
    { git.current_version(),             "String" },
    { "!\n",                             "Title" },
    {
      config.on_update_auto_quit and "Neovim will now update plugins and quit.\n\n"
      or "After plugins update, please restart.\n\n",
      "WarningMsg",
    },
  }

  if config.on_update_show_changelog and #changelog > 0 then
    vim.list_extend(summary, { { "Changelog:\n", "Title" } })
    vim.list_extend(summary, git.pretty_changelog(changelog))
    utils.echo(summary)
  end

end

--- Call lazy to update the plugins,
--- then close Neovim if `config.on_update_auto_quit = true`.
function M.trigger_post_update_events()
  local config = vim.g.distroupdate_config

  -- When the event `User DistroUpdateCompleted` is triggered at the end
  -- of this function, it closes nvim if `config.auto_quit` is true.
  vim.api.nvim_create_autocmd("User", {
    desc = "Auto quit Nvim after update completes",
    pattern = "DistroUpdateCompleted",
    callback = function()
      if config.on_update_auto_quit then
        vim.cmd("quitall")
      end
    end,
  })

  -- Reload lazy, then sync plugins.
  if config.update_plugins then
    require("lazy.core.plugin").load()
    require("lazy").sync({ wait = true })
  end
  utils.trigger_event("User DistroUpdateCompleted")
end

return M
