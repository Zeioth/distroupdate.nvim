--- ### General utils
--
--  DESCRIPTION:
--  General utility functions.

--    Helpers:
--      -> reload                → Reload nvim settings.
--      -> extend_tbl            → Add the content of a table to another table.
--      -> notify                → Send a notification with the plugin title.
--      -> trigger_event         → Manually trigger a event.
--      -> cmd                   → Run a shell command and return true/false.
--      -> os_path               → Convert a path to / (UNIX) or \ (Windows).

local M = {}

--- Partially reload Nvim user settings. Includes core vim options, mappings,
--- and highlights. This is an experimental feature and may lead to.
--- instabilities until restart.
---@param quiet? boolean Whether or not to notify on completion of reloading.
---@return boolean # True if the reload was successful, False otherwise.
function M.reload(quiet)
  -- Reload options, mappings and plugins (this is managed automatically by lazy).
  -- To avoid issues, don't try to reload your autocmds file unless you are sure.
  local was_modifiable = vim.opt.modifiable:get()
  if not was_modifiable then vim.opt.modifiable = true end
  local core_modules = vim.g.distroupdate_config.hot_reload_files
  local modules = vim.tbl_filter(
    function(module) return module:find "^user%." end,
    vim.tbl_keys(package.loaded)
  )

  vim.tbl_map(
    require("plenary.reload").reload_module,
    vim.list_extend(modules, core_modules)
  )
  local success = true
  for _, module in ipairs(core_modules) do
    module = M.filepath_to_module(module)
    local status_ok, fault = pcall(require, module)
    if not status_ok then
      vim.api.nvim_err_writeln("Failed to load " .. module .. "\n\n" .. fault)
      success = false
    end
  end
  if not was_modifiable then vim.opt.modifiable = false end
  if not quiet then -- if not quiet, then notify of result.
    if success then
      M.notify("Nvim successfully reloaded", vim.log.levels.INFO)
    else
      M.notify("Error reloading Nvim...", vim.log.levels.ERROR)
    end
  end

  return success
end

--- Merge extended options with a default table of options
---@param default? table The default table that you want to merge into
---@param opts? table The new options that should be merged with the default table
---@return table # The merged table
function M.extend_tbl(default, opts)
  opts = opts or {}
  return default and vim.tbl_deep_extend("force", default, opts) or opts
end

--- Serve a notification with a default title.
---@param msg string The notification body.
---@param type number|nil The type of the notification (:help vim.log.levels).
---@param opts? table The nvim-notify options to use (:help notify-options).
function M.notify(msg, type, opts)
  vim.schedule(function() vim.notify(
    msg, type, M.extend_tbl({ title = "Distroupdate.nvim" }, opts)) end)
end

--- Convenient wapper to save code when we Trigger events.
---@param event string Name of the event.
-- @usage To run a User event:   `trigger_event("User MyUserEvent")`
-- @usage To run a Neovim event: `trigger_event("BufEnter")`
function M.trigger_event(event)
  -- detect if event start with the substring "User "
  local is_user_event = string.match(event, "^User ") ~= nil

  vim.schedule(function()
    if is_user_event then
      -- Substract the substring "User " from the beginning of the event.
      event = event:gsub("^User ", "")
      vim.api.nvim_exec_autocmds("User", { pattern = event, modeline = false })
    else
      vim.api.nvim_exec_autocmds(event, { modeline = false })
    end
  end)
end

--- Run a shell command and capture the output and if the command
--- succeeded or failed
---@param cmd string|string[] The terminal command to execute
---@param show_error? boolean Whether or not to show an unsuccessful command
---                           as an error to the user
---@return string|nil # The result of a successfully executed command or nil
function M.cmd(cmd, show_error)
  if type(cmd) == "string" then cmd = vim.split(cmd, " ") end
  if vim.fn.has "win32" == 1 then cmd = vim.list_extend({ "cmd.exe", "/C" }, cmd) end
  local result = vim.fn.system(cmd)
  local success = vim.api.nvim_get_vvar "shell_error" == 0
  if not success and (show_error == nil or show_error) then
    vim.api.nvim_err_writeln(("Error running command %s\nError message:\n%s"):format(table.concat(cmd, " "), result))
  end
  return success and result:gsub("[\27\155][][()#;?%d]*[A-PRZcf-ntqry=><~]", "") or nil
end

--- Given a path, return its nvim module.
---@param path string Path of a file inside your nvim config directory.
---@return module string A string which is the module of the file path.
---@example  filepath_to_module(/home/user/.config/nvim/lua/base/1-options.lua)  -- returns "base.1-options"
function M.filepath_to_module(path)
    local filename = path:gsub("^.*[\\/]", "")  -- Remove leading directory path
    filename = filename:gsub("%..+$", "")       -- Remove file extension
    filename = filename:gsub("/", ".")          -- Replace '/' with '.'

    -- Extract directory name when constructed using vim.fn.stdpath()
    local directory = path:match(".*/") or ""
    directory = directory:gsub("^.*[\\/]", "") -- Remove leading directory path

    -- Check if directory is empty and try extracting it differently
    if directory == "" then
        directory = path:match("^.*/([^/]+)/.*$") or ""
    end

    return directory .. "." .. filename
end

---Given a string, convert 'slash' to 'inverted slash' if on windows, and vice versa on UNIX.
---Then return the resulting string.
---@param path string A path string.
---@return string|nil,nil path A path string formatted for the current OS.
function M.os_path(path)
  if path == nil then return nil end
  -- Get the platform-specific path separator
  local separator = package.config:sub(1,1)
  return string.gsub(path, '[/\\]', separator)
end

return M
