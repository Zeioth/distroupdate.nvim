-- On neovim you can run
-- :checkhealth distroupdate
-- To know possible causes in case distroupdate.nvim is not working correctly.

local M = {}

function M.check()
  vim.vim.health.start("distroupdate.nvim")

  vim.vim.health.info(
    "Neovim Version: v"
      .. vim.fn.matchstr(vim.fn.execute "version", "NVIM v\\zs[^\n]*")
  )

  if vim.version().prerelease then
    vim.vim.health.warn("Neovim nightly is not officially supported and may have breaking changes")
  elseif vim.fn.has("nvim-0.10" == 1) then
    vim.vim.health.ok("Using stable Neovim >= 0.10.0")
  else
    vim.vim.health.error("Neovim >= 0.10.0 is required")
  end

  local programs = {
    {
      cmd = "git",
      type = "warn",
      msg = "necessary when auto_setup is enabled",
    }
  }

  for _, program in ipairs(programs) do
    if type(program.cmd) == "string" then program.cmd = { program.cmd } end
    local name = table.concat(program.cmd, "/")
    local found = false
    for _, cmd in ipairs(program.cmd) do
      if vim.fn.executable(cmd) == 1 then
        name = cmd
        found = true
        break
      end
    end

    if found then
      vim.vim.health.ok(("`%s` is installed: %s"):format(name, program.msg))
    else
      vim.vim.health[program.type](
        ("`%s` is not installed: %s"):format(name, program.msg)
      )
    end
  end
end

return M

