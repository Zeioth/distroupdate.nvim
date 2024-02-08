# distroupdate.nvim
Distro agnostic Neovim plugin to upgrade your current distro from its github remote.

## How to use
Enable the commands you want to use the next way.

```lua
  {
    "Zeioth/distroupgrade.nvim",
    event = "VeryLazy",
    opts = {}
  },
```

## Options

|  Name               | Default value |Description                             |
|---------------------|---------------|----------------------------------------|
| **channel** | `stable` | Channel used by the command `:NvimUpdateConfig`. `stable` will update the distro from the latest available released version of your github repository. `nightly` will update the distro from the main branch of your github repository.
| **snapshot_file** | `<nvim_config>/lua/lazy_snapshot.lua"` | File used by the command `:NvimFreezePluginVersions` to write the plugins. 
| **snapshop_module** | `lazy_snapshop` | Name of the snapshot_file. TODO: We could programatically remove this option. |
| **rollback_file** | `<nvim_cache_dir>/rollback.lua` | File created by the command `:NvimRollbackCreate`, which is autocamically trigerred by `:NvimUpdateConfig`. |
| **release_tag** | `nil` | (optional) If this option is used, the option `channel` will be ignored, and the updater will use release you specify. The format must be semantic versioning, like: `v1.0`. |
| **hot_reload_files** | `{}` | The files included, will be hot reloaded, every time you write them. This way you can see the changes reflected without having to restart nvim. For example: `{ my_nvim_opts_file, my_nvim_mappings_file}`. Be aware this feature is experimental, and might not work in all cases yet. |
| **hot_reload_extra_behavior** | `function() end` | (optional) Extra things to do after the files defined in the option `hot_reload_files` are reloaded. For example: This can be handy if you want to re-apply your theme. |

## Commands

|  Command            | Description                             |
|---------------------|-----------------------------------------|
| **:NvimUpdateConfig** | Pulls the latest changes from the current git repository of your nvim config. Useful to keep your config updated when you use it in more than one machine. If the updates channel is `stable` this command will pull from the latest available tag release in your github repository. Only tag releases starting by 'v', such as v1.0.0 are recognized. It is also possible to define a specific stable version in `2-lazy.lua` by setting the option `stable_version_release`. If the channel is `nightly` it will pull from the nightly branch. Note that uncommitted local changes in your config will be lost after an update, so it's important you commit before updating your distro config. |
| **:NvimRollbackCreate** | Creates a recovery point. It is triggered automatically when running `:NvimUpdateConfig`. |
| **:NvimRollbackRestore** | Uses git to bring your config to the state it had when `:NvimRollbackCreate` was called. |
| **:NvimReload** | Hot reloads the config without leaving nvim. It can cause unexpected issues sometimes. It is automatically triggered when writing the files `1-options.lua` and `4-mappings`. |
| **:NvimUpdatePlugins** | Uses lazy to update the plugins. |
| **:NvimFreezePluginVersions** | Saves your current plugin versions into `lazy_versions.lua` in your config directory. If you are using the `stable` updates channel, this file will be used to decide what plugin versions will be installed, and even if you manually try to update your plugins using lazy package manager, the versions file will be respected. If you are using the `nightly` channel, the first time you open nvim, the versions from `lazy_versions.lua` will be installed, but it will be possible to download the last versions by manually updating your plugins with lazy. Note that after running this command, you can manually modify `lazy_versions.lua` in case you only want to freeze some plugins. |
| **:NvimVersion** | Prints the commit number of the current NormalNvim version. |

## Example of a real config

```lua
  -- distroupdate.nvim [distro update]
  -- https://github.com/Zeioth/distroupdate.nvim
  {
    "Zeioth/distroupdate.nvim",
    event = "VeryLazy",
    opts = {
      remote = "origin",
      channel = "stable",
      hot_reload_files = { "base.1-options", "base.4-mappings" },
      hot_reload_exta_behavior = function()
        vim.cmd ":silent! doautocmd ColorScheme"                             -- Heirline colorscheme reload event
        vim.cmd(":silent! colorscheme " .. base.default_colorscheme)         -- Nvm theme reload command
      end
    }
  }
```

## Credits
Most of the code included in this plugin come from AstroNvim, modified for the fork NormalNvim. So please support the projects if you enjoy this plugin.

## FAQ
* placeholder

## Roadmap
* TODO: Test all functions again.
