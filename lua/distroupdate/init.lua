-- This plugin is a neovim distro updater.

local cmd = vim.api.nvim_create_user_command
local config = require("dooku.config")
local updater = require("distroupdate.utils.updater")

local M = {}

function M.setup(opts)
  config.set(opts)

  -- Create commands so the user can use the plugin.
  cmd(
    "NvimChangelog",
    function() updater.changelog() end,
    { desc = "Check Nvim Changelog" }
  )
  cmd(
    "NvimUpdatePlugins",
    function() updater.update_packages() end,
    { desc = "Update Plugins and Mason" }
  )
  cmd(
    "NvimRollbackCreate",
    function() updater.create_rollback(true) end,
    { desc = "Create a rollback of '~/.config/nvim'." }
  )
  cmd(
    "NvimRollbackRestore",
    function() updater.rollback() end,
    { desc = "Restores '~/.config/nvim' to the last rollbacked state." }
  )
  cmd(
    "NvimFreezePluginVersions",
    function() updater.generate_snapshot(true) end,
    { desc = "Lock package versions (only lazy, not mason)." }
  )
  cmd(
    "NvimUpdateConfig", function() updater.update() end,
    { desc = "Update Nvim distro" }
  )
  cmd(
    "NvimVersion",
    function() updater.version() end,
    { desc = "Check Nvim distro Version" }
  )
  cmd(
    "NvimReload",
    function() require("distroupdate.utils").reload() end,
    { desc = "Reload Nvim without closing it (Experimental)" }
  )
end

return M
