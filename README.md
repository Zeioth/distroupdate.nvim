# distroupdate.nvim
Neovim plugin to upgrade your current neovim distro from its github remote

## How to use
Enable the commands you want to use the next way.

```lua
  {
    "Zeioth/distroupgrade.nvim",
    event = "VeryLazy",
    opts = {},
    config = function()
        -- Nvim updater commands
        -- If there is any command you don't need, you can delete it here.
        local updater = require("distroupdate.utils.updater")
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
  },
```
