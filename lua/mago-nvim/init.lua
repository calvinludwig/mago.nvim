local M = {}

function M.setup(opts)
  opts = opts or {}
  local exe = require 'mago-nvim.executable'
  exe.setup(opts)
  if not exe.init() then
    vim.notify('[mago.nvim] Mago executable not found', vim.log.levels.ERROR)
    return
  end

  require('mago-nvim.server').setup()
  require 'mago-nvim.commands'
end

return M
