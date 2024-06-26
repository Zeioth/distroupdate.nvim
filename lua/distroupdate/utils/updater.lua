--- ## Updater functions
--
--  DESCRIPTION:
--  Functions used by the commands of distroupdate.nvim

--    Functions:
--      -> generate_snapshot   → used by :DistroFreezePluginVersions.
--      -> version             → used by :DistroReadVersion.
--      -> changelog           → used by :DistroReadChangeLog.
--      -> create_rollback     → called automatically on :DistroUpdate.
--      -> rollback            → used by :DistroUpdateRevert.
--      -> attempt_update      → helper for update.
--      -> update              → used by :DistroUpdate.

local utils = require "distroupdate.utils"
local git = require "distroupdate.utils.git"

local M = {}

local function echo(messages)
  -- if no parameter provided, echo a new line
  messages = messages or { { "\n" } }
  if type(messages) == "table" then vim.api.nvim_echo(messages, false, {}) end
end

local function confirm_prompt(messages, type)
  return vim.fn.confirm(
    messages,
    "&Yes\n&No",
    (type == "Error" or type == "Warning") and 2 or 1,
    type or "Question"
  ) == 1
end

--- Helper function to generate a snapshot of the plugins currently installed.
---@param write? boolean Whether or not to write to the snapshot file (default: false)
---@return table # The plugin specification table of the snapshot
function M.generate_snapshot(write)
  local file

  -- get snapshot
  local snapshot_filename =  vim.fn.fnamemodify(vim.g.distroupdate_config.snapshot_file, ':t:r')
  local prev_snapshot = require(snapshot_filename)
  for _, plugin in ipairs(prev_snapshot) do
    prev_snapshot[plugin[1]] = plugin
  end

  -- helper function to get all plugins except the ones without URL.
  local function get_valid_plugins()
    local plugins = {}
    local all_plugins = assert(require("lazy").plugins())
    local invalid = 0

    -- exclude invalid plugins
    for _, plugin in ipairs(all_plugins) do
      local plugin_url = plugin[1]
      if plugin_url ~= nil then
        table.insert(plugins, plugin)
      else
        invalid = invalid + 1
      end
    end

    -- warnings if any
    if invalid > 0 then
      utils.notify(invalid .. " Plugins not added to the snapshot: No URL found.", vim.log.levels.WARN)
    end

    return plugins
  end

  -- get plugins
  local plugins = get_valid_plugins()
  table.sort(plugins, function(l, r) return l[1] < r[1] end)

  -- operate
  local function git_commit(dir)
    local commit =
        assert(utils.cmd("git -C " .. dir .. " rev-parse HEAD", false))
    if commit then return vim.trim(commit) end
  end
  if write == true then
    file = assert(io.open(vim.g.distroupdate_config.snapshot_file, "w"))
    file:write "return {\n"
  end
  local snapshot = vim.tbl_map(function(plugin)
    plugin =
    { plugin[1], commit = git_commit(plugin.dir), version = plugin.version }
    if prev_snapshot[plugin[1]] and prev_snapshot[plugin[1]].version then
      plugin.version = prev_snapshot[plugin[1]].version
    end
    if file then
      file:write(("  { %q, "):format(plugin[1]))
      if plugin.version then
        file:write(("version = %q "):format(plugin.version))
      else
        file:write(("commit = %q "):format(plugin.commit))
      end
      file:write "},\n"
    end
    return plugin
  end, plugins)
  if file then
    file:write "}\n"
    file:close()
  end
  utils.notify("Lazy packages locked to their current version.")
  return snapshot
end

--- Get the current distro version
--- @param quiet? boolean Whether to quietly execute or send a notification
--- @return string # The current distro version string
function M.version(quiet)
  local version = git.current_version(false) or "unknown"
  if vim.g.distroupdate_config.channel ~= "stable" then
    version = ("nightly (%s)"):format(version)
  end
  if version and not quiet then utils.notify("Version: " .. version) end
  return version
end

--- Get the full distro changelog
--- @param quiet? boolean Whether to quietly execute or display the changelog
--- @return table # The current distro changelog table of commit messages
function M.changelog(quiet)
  local summary = {}
  vim.list_extend(summary, git.pretty_changelog(git.get_commit_range()))
  if not quiet then echo(summary) end
  return summary
end

--- Create a table of options for the currently installed distro version
--- @param write? boolean Whether or not to write to the rollback file (default: false)
--- @return table # The table of updater options
function M.create_rollback(write)
  local snapshot = { branch = git.current_branch(), commit = git.local_head() }
  if snapshot.branch == "HEAD" then snapshot.branch = "main" end
  snapshot.remote = git.branch_remote(snapshot.branch, false) or "origin"
  snapshot.remotes = { [snapshot.remote] = git.remote_url(snapshot.remote) }

  if write == true then
    local file = assert(io.open(vim.g.distroupdate_config.rollback_file, "w"))
    file:write(
      "return " .. vim.inspect(snapshot, { newline = " ", indent = "" })
    )
    file:close()
  end
  -- Rollback file created
  utils.notify(
    "Rollback file created in ~/.cache/nvim\n\npointing to commit:\n"
    .. snapshot.commit
    .. "  \n\nYou can use :DistroUpdateRevert to revert ~/.config to this state."
  )
  return snapshot
end

--- Distro rollback to saved previous version.
function M.rollback()
  local rollback_avail, rollback_opts =
      pcall(dofile, vim.g.distroupdate_config.rollback_file)
  if not rollback_avail then
    utils.notify("No rollback file available", vim.log.levels.ERROR)
    return
  end
  M.update(rollback_opts)
end


--- Attempt an update of distro
--- @param target string The target if checking out a specific tag or commit or nil if just pulling
local function attempt_update(target, opts)
  -- if updating to a new stable version or a specific commit checkout the provided target
  if opts.channel == "stable" or opts.commit then
    return git.checkout(target, false)
    -- if no target, pull the latest
  else
    return git.pull(false)
  end
end

--- Distro updater function
--- @param opts? table the settings to use for the update
function M.update(opts)
  if not opts then opts = {
    remote = vim.g.distroupdate_config.remote,
    channel = vim.g.distroupdate_config.channel
  } end
  opts = require("distroupdate.utils").extend_tbl(
    { remote = "origin", show_changelog = true, auto_quit = false },
    opts
  )
  -- if the git command is not available, then throw an error
  if not git.available() then
    utils.notify(
      "git command is not available, please verify it is accessible in a command line. This may be an issue with your PATH",
      vim.log.levels.ERROR
    )
    return
  end

  -- if installed with an external package manager, disable the internal updater
  if not git.is_repo() then
    utils.notify(
      "Updater not available for non-git installations",
      vim.log.levels.ERROR
    )
    return
  end
  -- set up any remotes defined by the user if they do not exist
  for remote in pairs(opts.remotes and opts.remotes or {}) do
    local url = git.remote_url(remote, false)
    -- Show remote we are using
    echo {
      { "Checking remote " },
      { remote,                       "Title" },
      { " which is currently set to " },
      { url,                          "WarningMsg" },
      { "..." },
    }
  end
  local is_stable = opts.channel == "stable"
  if is_stable then
    opts.branch = "main"
  elseif not opts.branch then
    opts.branch = "nightly"
  end
  -- setup branch if missing
  if not git.ref_verify(opts.remote .. "/" .. opts.branch, false) then
    git.remote_set_branches(opts.remote, opts.branch, false)
  end
  -- fetch the latest remote
  if not git.fetch(opts.remote) then
    vim.api.nvim_err_writeln("Error fetching remote: " .. opts.remote)
    return
  end
  -- switch to the necessary branch only if not on the stable channel
  if not is_stable then
    local local_branch = (
      opts.remote == "origin" and "" or (opts.remote .. "_")
    ) .. opts.branch
    if git.current_branch() ~= local_branch then
      echo {
        { "Switching to branch: " },
        { opts.remote .. "/" .. opts.branch .. "\n\n", "String" },
      }
      if not git.checkout(local_branch, false) then
        git.checkout(
          "-b " .. local_branch .. " " .. opts.remote .. "/" .. opts.branch,
          false
        )
      end
    end
    -- check if the branch was switched to successfully
    if git.current_branch() ~= local_branch then
      vim.api.nvim_err_writeln(
        "Error checking out branch: " .. opts.remote .. "/" .. opts.branch
      )
      return
    end
  end
  local source = git.local_head() -- calculate current commit
  local target                    -- calculate target commit
  if is_stable then               -- if stable get tag commit
    local version_search = vim.g.distroupdate_config.release_tag or "latest"
    opts.version = git.latest_version(git.get_versions(version_search))
    if not opts.version then -- continue only if stable version is found
      vim.api.nvim_err_writeln("Error finding version: " .. version_search)
      return
    end
    target = git.tag_commit(opts.version)
  elseif opts.commit then -- if commit specified use it
    target = git.branch_contains(opts.remote, opts.branch, opts.commit)
        and opts.commit
        or nil
  else -- get most recent commit
    target = git.remote_head(opts.remote, opts.branch)
  end
  if not source or not target then -- continue if current and target commits were found
    vim.api.nvim_err_writeln "Error checking for updates"
    return
  elseif source == target then
    echo { { "No changes available", "String" } }
    return
  elseif -- prompt user if they want to accept update
      not opts.skip_prompts
      and not confirm_prompt(
        ("Update avavilable to %s\nUpdating requires a restart, continue?"):format(
          is_stable and opts.version or target
        )
      )
  then
    echo({ { "Update cancelled", "WarningMsg" } })
    return
  else                      -- perform update
    M.create_rollback(true) -- create rollback file before updating

    -- calculate and print the changelog
    local changelog = git.get_commit_range(source, target)
    local breaking = git.breaking_changes(changelog)
    if
        #breaking > 0
        and not opts.skip_prompts
        and not confirm_prompt(
          ("Update contains the following breaking changes:\n%s\nWould you like to continue?"):format(
            table.concat(breaking, "\n")
          ),
          "Warning"
        )
    then
      echo({ { "Update cancelled", "WarningMsg" } })
      return
    end -- attempt an update
    local updated = attempt_update(target, opts)
    -- check for local file conflicts and prompt user to continue or abort
    git.hard_reset(source)
    updated = attempt_update(target, opts)
    -- if update was unsuccessful throw an error
    if not updated then
      vim.api.nvim_err_writeln "Error occurred performing update"
      return
    end
    -- print a summary of the update with the changelog
    local summary = {
      { "Nvim updated successfully to ", "Title" },
      { git.current_version(),           "String" },
      { "!\n",                           "Title" },
      {
        opts.auto_quit and "Nvim will now update plugins and quit.\n\n"
        or "After plugins update, please restart.\n\n",
        "WarningMsg",
      },
    }
    if opts.show_changelog and #changelog > 0 then
      vim.list_extend(summary, { { "Changelog:\n", "Title" } })
      vim.list_extend(summary, git.pretty_changelog(changelog))
    end
    echo(summary)

    -- if the user wants to auto quit, create an autocommand to quit Nvim on the update completing
    if opts.auto_quit then
      vim.api.nvim_create_autocmd("User", {
        desc = "Auto quit Nvim after update completes",
        pattern = "ConfigUpdateCompleted",
        command = "quitall",  -- Auto close nvim after a update
      })
    end

    require("lazy.core.plugin").load()   -- force immediate reload of lazy
    require("lazy").sync { wait = true } -- sync new plugin spec changes
    utils.trigger_event("User ConfigUpdateCompleted")
  end
end

return M
