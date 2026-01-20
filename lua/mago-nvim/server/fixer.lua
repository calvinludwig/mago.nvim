local M = {}

function M.fix(bufnr, rule)
  local lint = require 'mago-nvim.run.lint'
  local filepath = vim.api.nvim_buf_get_name(bufnr)

  local is_modified = vim.bo[bufnr].modified

  if is_modified or not filepath then
    vim.notify '[mago.nvim] Save the file before fixing the issues'
    return
  end

  lint.fix(filepath, rule)

  vim.api.nvim_buf_call(bufnr, function()
    vim.cmd 'edit!'
  end)
end

return M
