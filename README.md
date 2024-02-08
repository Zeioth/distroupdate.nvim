# distroupdate.nvim
Distro agnostic Neovim plugin to upgrade your current distro from its github remote.

## How to use
Enable the commands you want to use the next way.

```lua
  {
    "Zeioth/distroupgrade.nvim",
    event = "VeryLazy",
    opts = {
      remote = "origin",
      channel = "stable",
      snapthot_file = vim.fn.stdpath "config" .. "/lua/lazy_snapshot.lua",
      snapthot_module = "lazy_snapshot",
      rollback_file = vim.fn.stdpath "cache" .. "/rollback.lua",
      release_tag = nil,
      hot_reload_files = opts.hot_reload_files or { "base.1-options", "base.4-mappings" }
    },
    config = function()
      -- Hot reload on config change (optional).
      autocmd({ "BufWritePost" }, {
        desc = ":NvimReload if the buffer is a file to be hot reloaded.",
        callback = function()
          local bufPath = vim.fn.expand "%:p"
          for _, filePath in ipairs(hot_reload_files) do
            if filePath == bufPath then vim.cmd "NvimReload" end
          end
        end,
      })
    end
  },
```

## Commands

|  Command            | Description                             |
|---------------------|-----------------------------------------|
| **:checkhealth base** | Check the system dependencies you are missing. |
| **:NvimUpdateConfig** | Pulls the latest changes from the current git repository of your nvim config. Useful to keep your config updated when you use it in more than one machine. If the updates channel is `stable` this command will pull from the latest available tag release in your github repository. Only tag releases starting by 'v', such as v1.0.0 are recognized. It is also possible to define a specific stable version in `2-lazy.lua` by setting the option `stable_version_release`. If the channel is `nightly` it will pull from the nightly branch. Note that uncommitted local changes in your config will be lost after an update, so it's important you commit before updating your distro config. |
| **:NvimRollbackCreate** | Creates a recovery point. It is triggered automatically when running `:NvimUpdateConfig`. |
| **:NvimRollbackRestore** | Uses git to bring your config to the state it had when `:NvimRollbackCreate` was called. |
| **:NvimReload** | Hot reloads the config without leaving nvim. It can cause unexpected issues sometimes. It is automatically triggered when writing the files `1-options.lua` and `4-mappings`. |
| **:NvimUpdatePlugins** | Uses lazy to update the plugins. |
| **:NvimFreezePluginVersions** | Saves your current plugin versions into `lazy_versions.lua` in your config directory. If you are using the `stable` updates channel, this file will be used to decide what plugin versions will be installed, and even if you manually try to update your plugins using lazy package manager, the versions file will be respected. If you are using the `nightly` channel, the first time you open nvim, the versions from `lazy_versions.lua` will be installed, but it will be possible to download the last versions by manually updating your plugins with lazy. Note that after running this command, you can manually modify `lazy_versions.lua` in case you only want to freeze some plugins. |
| **:NvimVersion** | Prints the commit number of the current NormalNvim version. |

## Credits
Most of the code included in this plugin come from AstroNvim, modified for the fork NormalNvim. So please support the projects if you enjoy this plugin.

## Roadmap
* TODO: Write unit tests so we can run the commands one by one and see if they work ok.
* ISSUE: Some parts of the updater still rely on NormalNvim `2-lazy.lua` → `base.updater` table, so we should provide a distroupdater option to allow users to define such options for the updater (and tell users to use the values they use for lazy, if any), as that value has to be there no matter what, because Lazy is loaded before any other plugin.
* Remove the utils that are not actually necessary from `utils/init.lua` → Also, remove from `utils/init.lua` the things that were only used for the updater.
* Create actual configuration options, instead of using lazy `config`.
* On NormalNvim mason plugin, add a checking to define the CMD only if distroupdate is present.

