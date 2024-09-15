-- This plugin is a neovim distro updater.
local M = {}
local utils = require("distroupdate.utils")

---Set a default value for an option in a boolean logic safe way.
---@param opt any A option defined by the user.
---@param default any A default value.
local function set_default(opt, default)
  return opt == nil and default or opt
end

---Parse user options, or set the defaults
---@param opts table A table with options to set.
function M.set(opts)
  -- UPDATER OPTIONS
  M.channel = opts.channel or "stable"
  M.release_tag = opts.release_tag or nil
  M.commit = opts.commit or nil
  M.remote = opts.remote or "origin"

  -- `config.branch` is auto-setted depending the value of `config.channel`.
  M.branch = nil
  if M.channel == "stable" then M.branch = "main" else M.branch = "nightly" end

  -- No released_tag? set it to latest
  if not M.release_tag then M.release_tag = "latest" end

  -- UPDATER UX OPTS
  M.ovewrite_uncommited_local_changes = set_default(opts.ovewrite_uncommited_local_changes, true)
  M.update_plugins = set_default(opts.update_plugins, true)
  M.on_update_show_changelog = set_default(opts.on_update_show_changelog, true)
  M.on_update_auto_quit = set_default(opts.on_update_auto_quit, false)
  M.auto_accept_prompts = set_default(opts.on_update_auto_quit, false)

  -- VERSIONING OPTS
  M.rollback_file = opts.rollback_file or utils.os_path(vim.fn.stdpath "cache" .. "/rollback.lua")
  M.snapshot_file = opts.snapshot_file or utils.os_path(vim.fn.stdpath "config" .. "/lua/lazy_snapshot.lua")

  -- HOT RELOAD OPTS
  M.hot_reload_callback = opts.hot_reload_exta_behavior or function() end
  M.hot_reload_files = opts.hot_reload_files or {}

  -- expose the config as global
  vim.g.distroupdate_config = M
end

return M
