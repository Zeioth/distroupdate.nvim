-- This plugin is a neovim distro updater.

local cmd = vim.api.nvim_create_user_command
local config = require("distroupdate.config")
local updater = require("distroupdate.cmds.updater")
local versioning = require("distroupdate.cmds.versioning")

local M = {}

function M.setup(opts)
  config.set(opts)

  -- Create commands so the user can use the plugin.
  cmd(
    "DistroFreezePluginVersions",
    function() versioning.freeze_plugin_versions() end,
    { desc = "Lock package versions (lazy)." }
  )
  cmd(
    "DistroReadChangelog",
    function() versioning.print_changelog() end,
    { desc = "Check Nvim Changelog." }
  )
  cmd(
    "DistroReadVersion",
    function() versioning.notify_version() end,
    { desc = "Check distro git Version." }
  )
  cmd(
    "DistroUpdate", function() updater.update() end,
    { desc = "Update your config dir from its git repo." }
  )
  cmd(
    "DistroUpdateRevert",
    function() versioning.rollback() end,
    { desc = "Restores '~/.config/nvim' to the version it had before running :DistroUpdate." }
  )
end

return M
