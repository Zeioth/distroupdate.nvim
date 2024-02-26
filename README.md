# distroupdate.nvim
Distro agnostic Neovim plugin to upgrade your current distro from its github remote.

![screenshot_2024-02-09_21-31-46_988972150](https://github.com/Zeioth/distroupdate.nvim/assets/3357792/69bacfe7-ffb7-4f59-91f8-a41bbe2f7ed3)

<div align="center">
  <a href="https://discord.gg/ymcMaSnq7d" rel="nofollow">
      <img src="https://img.shields.io/discord/1121138836525813760?color=azure&labelColor=6DC2A4&logo=discord&logoColor=black&label=Join the discord server&style=for-the-badge" data-canonical-src="https://img.shields.io/discord/1121138836525813760">
    </a>
</div>

## Why
So you can always have a fresh nvim config when you use Nvim in multiple machines. Just run `:NvimConfigUpdate` and get the latest available version from your github repository.

## Warning
Running `:NvimConfigUpdate` will ovewrite any uncommited change in your local nvim config, so make sure you push your local changes before running it.

## How to install
On lazy

```lua
{
  "Zeioth/distroupgrade.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  event = "VeryLazy",
  opts = {}
}
```

## Available options
All options described here are 100% optional and you don't need to defined them to use this plugin.

|  Name               | Default value |Description                             |
|---------------------|---------------|----------------------------------------|
| **channel** | `stable` | Channel used by the command `:NvimUpdateConfig`. `stable` will update the distro from the latest available released version of your github repository. `nightly` will update the distro from the main branch of your github repository.
| **hot_reload_files** | `{}` | The files included, will be hot reloaded every time you write them. This way you can see the changes in your config reflected without having to restart nvim. For example: `{ my_nvim_opts_file, my_nvim_mappings_file}`. Be aware this feature is experimental, and might not work in all cases yet. |
| **hot_reload_callback** | `function() end` | (optional) Extra things to do after the files defined in the option `hot_reload_files` are reloaded. For example: This can be handy if you want to re-apply your theme. |
| **release_tag** | `nil` |  If this option is specified, the option `channel` will be ignored, and the updater will download the release you specify. The format must be semantic versioning, like: `"v1.0"`. |
| **remote** | `origin` | Github remote of your distro repository. |
| **snapshot_file** | `<nvim_config_dir>/lua/lazy_snapshot.lua` | File used by the command `:NvimFreezePluginVersions` to write the plugins. 
| **rollback_file** | `<nvim_cache_dir>/rollback.lua` | File created by the command `:NvimRollbackCreate`, which is autocamically trigerred by `:NvimUpdateConfig`. |

## Available commands

|  Command            | Description                             |
|---------------------|-----------------------------------------|
| **:NvimUpdateConfig** | If the value of the option `channel` is `stable`, it will update from the latest available released version of the `remote` of the git repository of your nvim config. If the value of `channel` is `nightly`, it will update from the latest changes in the branch `nightly` of the git repository of you nvim config.|
| **:NvimRollbackCreate** | Creates a recovery point. It is triggered automatically when running `:NvimUpdateConfig`. |
| **:NvimRollbackRestore** | Uses git to bring your config to the state it had when `:NvimRollbackCreate` was called. |
| **:NvimReload** | Hot reloads the files specified in the optin `hot_reload_files` without need to restart nvim. |
| **:NvimUpdatePlugins** | Uses lazy to update the plugins, and Mason to update all your lsp servers, linters, DAP adapters, and formatters. |
| **:NvimFreezePluginVersions** | Saves your current plugin versions into `lazy_versions.lua` in your config directory. You can import this file and pass it to your lazy config, so it respect your locked versions. [Check the option `spec` in lazy](https://github.com/folke/lazy.nvim). |
| **:NvimVersion** | Prints the commit number of the current NormalNvim version. |

## Events (Optional)
Distroupdate.nvim trigger two different events:

| Event | Description |
|--------|------------|
| `User MasonUpdateCompleted` | You can listen to this event on an autocmd if you want something to happen after Mason end installing packages during `:NvimUpdateConfig` or `:NvimUpdatePlugins`. |
| `User ConfigUpdateCompleted` | You can listen to this event on an autocmd if you want something to happen after `:NvimUpdateConfig` ends. |

## Example of a real config

```lua
-- distroupdate.nvim [distro update]
-- https://github.com/Zeioth/distroupdate.nvim
{
  "Zeioth/distroupdate.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  event = "VeryLazy",
  opts = function()
    local config_dir = vim.fn.stdpath "config" .. "/lua/base/"
    return {
      remote = "origin",
      channel = "stable",                                             -- stable/nightly.
      release_tag = nil,                                              -- in case you wanna freeze a specific distro version.
      hot_reload_files = {
        config_dir .. "1-options.lua",
        config_dir .. "4-mappings.lua"
      },
      hot_reload_extra_behavior = function()
        vim.cmd ":silent! doautocmd ColorScheme"                     -- heirline colorscheme reload event.
        vim.cmd(":silent! colorscheme " .. base.default_colorscheme) -- nvim     colorscheme reload command.
      end
    }
  end
},
```

## Credits
Many of the GPL3 lua libraries this plugin use come from AstroNvim and NormalNvim. So please support both projects if you enjoy this plugin.

## FAQ

* **Is this plugin automatic?** NO. This plugin will do nothing unless you run one of its commands.
* **Where do the updates come from?** From your own git repo. You are the only one in control.
