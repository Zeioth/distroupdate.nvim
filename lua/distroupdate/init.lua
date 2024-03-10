-- This plugin is a neovim distro updater.

local cmd = vim.api.nvim_create_user_command
local config = require("distroupdate.config")
local updater = require("distroupdate.utils.updater")

local M = {}

function M.setup(opts)
  config.set(opts)

  -- Create commands so the user can use the plugin.
  cmd(
    "DistroFreezePluginVersions",
    function() updater.generate_snapshot(true) end,
    { desc = "Lock package versions (lazy)." }
  )
  cmd(
    "DistroReadChangelog",
    function() updater.changelog() end,
    { desc = "Check Nvim Changelog." }
  )
  cmd(
    "DistroReadVersion",
    function() updater.version() end,
    { desc = "Check distro git Version." }
  )
  cmd(
    "DistroUpdate", function() updater.update() end,
    { desc = "Update your config dir from its git repo." }
  )
  cmd(
    "DistroUpdateRevert",
    function() updater.rollback() end,
    { desc = "Restores '~/.config/nvim' to the version it had before running :DistroUpdate." }
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
