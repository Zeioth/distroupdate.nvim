-- This plugin is a neovim distro updater.
local M = {}
local utils = require("distroupdate.utils")


---Parse user options, or set the defaults
---@param opts table A table with options to set.
function M.set(opts)
  M.channel = opts.channel or "stable"
  M.hot_reload_extra_behavior = opts.hot_reload_exta_behavior or function() end
  M.hot_reload_files = opts.hot_reload_files or {}
  M.release_tag = opts.release_tag or nil
  M.remote = opts.remote or "origin"
  M.rollback_file = opts.rollback_file or  utils.os_path(vim.fn.stdpath "cache" .. "/rollback.lua")
  M.snapshot_file = opts.snapshot_file or utils.os_path(vim.fn.stdpath "config" .. "/lua/lazy_snapshot.lua")

  -- expose the config as global
  vim.g.distroupdate_config = M
end

return M
