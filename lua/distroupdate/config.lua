-- This plugin is a neovim distro updater.
local M = {}
local utils = require("distroupdate.utils")


---Parse user options, or set the defaults
---@param opts table A table with options to set.
function M.set(opts)
  M.remote = opts.remote or "origin"
  M.channel = opts.channel or "stable"
  M.snapthot_file = opts.snapthot_file or utils.os_path(vim.fn.stdpath "config" .. "/lua/lazy_snapshot.lua")
  M.snapthot_module = opts.snapthot_module or "lazy_snapshot"
  M.rollback_file = opts.rollback_file or  utils.os_path(vim.fn.stdpath "cache" .. "/rollback.lua")
  M.release_tag = opts.release_tag or ""
  M.hot_reload_files = opts.hot_reload_files or {}

  -- expose the config as global
  vim.g.distroupdate_config = M
end

return M
