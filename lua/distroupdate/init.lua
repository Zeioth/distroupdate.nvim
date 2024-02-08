-- This plugin is a neovim distro updater.

local cmd = vim.api.nvim_create_user_command
local config = require("distroupdate.config")
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

  -- Autocmds
  vim.api.nvim_create_autocmd({ "BufWritePost" }, {
    desc = ":NvimReload if any of the buffers in the option `hot_reload_files` are written.",
    callback = function()
      local bufPath = vim.fn.expand "%:p"
      for _, filePath in ipairs(opts.hot_reload_files) do
        if filePath == bufPath then
          vim.cmd "NvimReload"
          opts.hot_reload_extra_behavior()
        end
      end
    end
  })

end

return M
