-- This plugin is a neovim distro updater.
local M = {}
local utils = require("distroupdate.utils")


---Parse user options, or set the defaults
---@param opts table A table with options to set.
function M.set(opts)
  M.channel = opts.channel or "stable"
  M.hot_reload_callback = opts.hot_reload_exta_behavior or function() end
  M.hot_reload_files = opts.hot_reload_files or {}
  M.release_tag = opts.release_tag or nil
  M.commit = opts.commit or nil
  M.remote = opts.remote or "origin"
  M.rollback_file = opts.rollback_file or utils.os_path(vim.fn.stdpath "cache" .. "/rollback.lua")
  M.snapshot_file = opts.snapshot_file or utils.os_path(vim.fn.stdpath "config" .. "/lua/lazy_snapshot.lua")

  -- DEBUG OPTIONS (not currently exposed to the user)
  M.on_update_show_changelog = true
  M.on_update_auto_quit = false

  -- `config.branch` is auto-setted depending the value of `config.channel`.
  M.branch = nil
  if M.channel == "stable" then M.branch = "main" else M.branch = "nightly" end

  -- No released_tag? set it to latest
  if not M.release_tag then M.release_tag = "latest" end

  -- expose the config as global
  vim.g.distroupdate_config = M
end

return M
