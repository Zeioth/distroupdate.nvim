# distroupdate.nvim
Distro agnostic Neovim plugin to upgrade your current distro from its github remote.

![screenshot_2024-03-10_23-20-38_444541684](https://github.com/Zeioth/distroupdate.nvim/assets/3357792/c86e1978-9095-4c50-9365-e130ff69a7d2)

<div align="center">
  <a href="https://discord.gg/ymcMaSnq7d" rel="nofollow">
      <img src="https://img.shields.io/discord/1121138836525813760?color=azure&labelColor=6DC2A4&logo=discord&logoColor=black&label=Join the discord server&style=for-the-badge" data-canonical-src="https://img.shields.io/discord/1121138836525813760">
    </a>
</div>

## Table of contents

- [Why](#why)
- [How to install](#how-to-install)
- [Available commands](#available-commands)
- [Available options](#available-options)
- [Events (Optional)](#events-optional)
- [Example of a real config](#example-of-a-real-config)
- [FAQ](#faq)

## Why
If you use Neovim in multiple machines, you can use the command `:DistroUpdate` to get the latest changes of your config from your GitHub repository from any device.

If you are developing a Neovim distro, you can ship this plugin, and users will get updates from your distro GitHub repository when they run `:DistroUpdate`.

### Warning
Currently, running `:DistroUpdate` will overwrite any uncommited change in your local nvim config.

## How to install
This plugin requires you to use lazy package manager

```lua
{
  "Zeioth/distroupgrade.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "Zeioth/mason-extra-cmds"
  },
  event = "VeryLazy",
  opts = {}
}
```

## Available commands

|  Command            | Description                             |
|---------------------|-----------------------------------------|
| **:DistroUpdate** | If the value of the option `channel` is `stable`, it will update from the latest available released version of the `remote` of the git repository of your nvim config. If the value of `channel` is `nightly`, it will update from the latest changes in the branch `nightly` of the git repository of you nvim config.|
| **:DistroUpdateRevert** | Uses git to bring your config to the state it had before running `:DistroUpdate`. |
| **:DistroFreezePluginVersions** | Saves your current plugin versions into `lazy_versions.lua` in your config directory. You can import this file and pass it to your lazy config, so it respect your locked versions. [Check the option `spec` in lazy](https://github.com/folke/lazy.nvim). |
| **:DistroReadVersion** | Prints the commit number of the current distro version. |
| **:DistroReadChangelog** | Prints the changelog. |

## Available options
All options described here are 100% optional and you don't need to define them to use this plugin.

|  Name               | Default value |Description                             |
|---------------------|---------------|----------------------------------------|
| **channel** | `stable` | Channel used by the command `:DistroUpdate`. `stable` will update the distro from the latest available released version of your github repository. `nightly` will update the distro from the main branch of your github repository.
| **hot_reload_files** | `{}` | The files included, will be hot reloaded every time you write them. This way you can see the changes in your config reflected without having to restart nvim. For example: `{ my_nvim_opts_file, my_nvim_mappings_file}`. Be aware this feature is experimental, and might not work in all cases yet. |
| **hot_reload_callback** | `function() end` | (optional) Extra things to do after the files defined in the option `hot_reload_files` are reloaded. For example: This can be handy if you want to re-apply your theme. |
| **release_tag** | `nil` |  If this option is specified, the option `channel` will be ignored, and the updater will download the release you specify. The format must be semantic versioning, like: `"v1.0"`. |
| **remote** | `origin` | Github remote of your distro repository. |
| **snapshot_file** | `<nvim_config_dir>/lua/lazy_snapshot.lua` | File used by the command `:DistroFreezePluginVersions` to write the plugins. 
| **rollback_file** | `<nvim_cache_dir>/rollback.lua` | Rollback file autocamically trigerred by `:DistroUpdate`. This file will be used when you use `:DistroUpdateRevert`|

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
