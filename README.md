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
      snapshot_file = vim.fn.stdpath "config" .. "/lua/lazy_snapshot.lua",
      snapshot_module = "lazy_snapshot",
      rollback_file = vim.fn.stdpath "cache" .. "/rollback.lua",
      release_tag = nil,
      hot_reload_files = opts.hot_reload_files or { "base.1-options", "base.4-mappings" }
    },
    config = function()
      -- Hot reload on config change (optional).
      vim.api.nvim_create_autocmd({ "BufWritePost" }, {
        desc = ":NvimReload the files defined on opts.hot_reload_files on write.",
        callback = function() vim.cmd "NvimReload" end,
      })
    end
  },
```

## Options

|  Name               | Default value |Description                             |
|---------------------|---------------|----------------------------------------|
| **remote** | `origin` | The github remote of your distro repository. |
| **channel** | `stable` | Channel used by the command `:NvimUpdateConfig`. `stable` will update the distro from the latest available released version of your github repository. `nightly` will update the distro from the main branch of your github repository.
| **snapshot_file** | `<nvim_config>/lua/lazy_snapshot.lua"` | File used by the command `:NvimFreezePluginVersions` to write the plugins. 
| **snapshop_module** | `lazy_snapshop` | Name of the snapshot_file. TODO: We could programatically remove this option. |
| **rollback_file** | `<nvim_cache_dir>/rollback.lua` | File created by the command `:NvimRollbackCreate`, which is autocamically trigerred by `:NvimUpdateConfig`. |
| **release_tag** | `nil` | If this option is setted, the option `channel` will be ignored, and the updater will use release you specify. The format must be semantic versioning, like: `v1.0`. |
| **hot_reload_files** | `{}` | The files included, will be hot reloaded, every time you write them. This way you can see the changes reflected without having to restart nvim. For example: `{ my_nvim_opts_file, my_nvim_mappings_file}`. Be aware this feature is experimental, and might not work in all cases yet. |

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
      release_tag = nil,
      hot_reload_files = { "base.1-options", "base.4-mappings" }
    },
    config = function(opts)
      require("distroupdate").setup(opts)

      -- Enable hot reload (optional).
      vim.api.nvim_create_autocmd({ "BufWritePost" }, {
        desc = ":NvimReload if the buffer is a file to be hot reloaded.",
        callback = function()
          vim.cmd "NvimReload"                                               -- Reload files in opts.hot_reload_files
          vim.cmd ":silent! doautocmd ColorScheme"                           -- Also for heirline colorscheme
          vim.cmd(":silent! colorscheme " .. base.default_colorscheme)       -- Also for nvim colorscheme
        end,
      })
    end
  },
```

## Credits
Most of the code included in this plugin come from AstroNvim, modified for the fork NormalNvim. So please support the projects if you enjoy this plugin.

## FAQ
* placeholder

## Roadmap
* TODO: Document the new added options.
* TODO: We should create a autocmd for NvimReload by default on setup().
* TODO: We should expose the option `hot_reload_extra_behavior` which gets a function, in case someone wants to do something extra in the autocmd, like reloading its nvim theme.
* TODO: In NormalNvim, adap the format of base.updater to the format of distroupdate.nvim, so it matches, and uses its settings if present.
* TODO: Test all functions again.
