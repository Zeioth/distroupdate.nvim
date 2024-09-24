--- ### General utils
--
--  DESCRIPTION:
--  General utility functions.

--    Helpers:
--      -> run_cmd               → Run a shell command and return true/false.
--      -> notify                → Send a notification with the plugin title.
--      -> trigger_event         → Manually trigger a event.
--      -> os_path               → Convert a path to / (UNIX) or \ (Windows).
--      -> echo                  > Displaye a colorized message.
--      -> configm_prompt        → Asks the user for confirmation.

local M = {}

--- Run a shell command and capture the output and whether the command
--- succeeded or failed.
--- @param cmd string|string[] The terminal command to execute.
--- @param show_error? boolean If true, print errors if the command fails.
--- @return string|nil # The result of a successfully executed command, or nil if it failed.
function M.run_cmd(cmd, show_error)
  -- Split cmd string into a list, if needed.
  if type(cmd) == "string" then
    cmd = vim.split(cmd, " ")
  end

  -- If windows, and prepend cmd.exe
  if vim.fn.has("win32") == 1 then
    cmd = vim.list_extend({ "cmd.exe", "/C" }, cmd)
  end

  -- Execute cmd and store result (output or error message)
  local result = vim.fn.system(cmd)
  local success = vim.api.nvim_get_vvar("shell_error") == 0

  -- If the command failed and show_error is true or not provided, print error.
  if not success and (show_error == nil or show_error) then
    vim.api.nvim_err_writeln(
      ("Error running command %s\nError message:\n%s"):format(
        table.concat(cmd, " "), -- Convert the cmd back to string.
        result                  -- Show the error result
      )
    )
  end

  -- strip out terminal escape sequences and control characters.
  local cleaned_result = result:gsub("[\27\155][][()#;?%d]*[A-PRZcf-ntqry=><~]", "")

  -- Return the cleaned result if the command succeeded, or nil if it failed
  return (success and cleaned_result) or nil
end

--- Serve a notification with a default title.
--- @param msg string The notification body.
--- @param type number|nil The type of the notification (:help vim.log.levels).
--- @param opts? table The nvim-notify options to use (:help notify-options).
function M.notify(msg, type, opts)
  vim.schedule(function()
    vim.notify(msg, type,
      vim.tbl_deep_extend(
        "force", { title = "Distroupdate.nvim" }, opts or {})
    )
  end)
end

--- Convenient wapper to save code when we Trigger events.
--- @param event string Name of the event.
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

--- Given a string, convert 'slash' to 'inverted slash' if on windows, and vice versa on UNIX.
--- Then return the resulting string.
--- @param path string A path string.
--- @return string|nil,nil path A path string formatted for the current OS.
function M.os_path(path)
  if path == nil then return nil end
  -- Get the platform-specific path separator
  local separator =  package.config:sub(1,1)
  return string.gsub(path, '[/\\]', separator)
end


--- if no parameter provided, echo a new line
--- @param messages table A table like { {""}, {""}... }
 function M.echo(messages)
  messages = messages or { { "\n" } }
  if type(messages) == "table" then vim.api.nvim_echo(messages, false, {}) end
end

--- Prompt the user to confirm.
--- @param message string A table like { {""}, {""}... }
--- @param type? string It can be `Error`, `Warning`, or `Question`.
function M.confirm_prompt(message, type)
  return vim.fn.confirm(
    message,
    "&Yes\n&No",
    (type == "Error" or type == "Warning") and 2 or 1,
    type or "Question"
  ) == 1
end

return M
