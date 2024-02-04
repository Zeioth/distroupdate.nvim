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
      -- Hot reload on config change (optional).
      autocmd({ "BufWritePost" }, {
        desc = "When writing a buffer, :NvimReload if the buffer is a config file.",
        callback = function()
          local filesThatTriggerReload = {
            vim.fn.stdpath "config" .. "lua/base/1-options.lua",  -- use your file
            vim.fn.stdpath "config" .. "lua/base/4-mappings.lua", -- use your file
          }

          local bufPath = vim.fn.expand "%:p"
          for _, filePath in ipairs(filesThatTriggerReload) do
            if filePath == bufPath then vim.cmd "NvimReload" end
          end
        end,
      })
    end
  },
```
