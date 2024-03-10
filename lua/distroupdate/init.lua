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
    { desc = "Check Nvim Changelog." }
  )
  cmd(
    "NvimDistroUpdate", function() updater.update() end,
    { desc = "Update your config dir from its git repo." }
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
    "NvimVersion",
    function() updater.version() end,
    { desc = "Check Nvim distro Version" }
  )

  -- Autocmds
  vim.api.nvim_create_autocmd({ "BufWritePost" }, {
    desc = ":NvimReload if a `hot_reload_files` buf is written.",
    callback = function()
      local bufPath = vim.fn.expand "%:p"
      for _, filePath in ipairs(opts.hot_reload_files) do
        if filePath == bufPath then
          require("distroupdate.utils").reload()
          opts.hot_reload_callback()
        end
      end
    end
  })

end

return M
