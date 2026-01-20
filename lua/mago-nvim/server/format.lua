local M = {}

function M.format_uri(uri)
  local fmt = require 'mago-nvim.run.fmt'
  local bufnr = vim.uri_to_bufnr(uri)
  local filepath = vim.uri_to_fname(uri)
  local is_modified = vim.bo[bufnr].modified

  if not is_modified and filepath then
    fmt.format_filepath(filepath)
    vim.api.nvim_buf_call(bufnr, function()
      vim.cmd 'edit!'
    end)
    return
  end

  local old_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local input = table.concat(old_lines, '\n')

  local output = fmt.format_stdin(input)
  if output == '' then
    return
  end
  local lines = vim.split(output, '\n', { plain = true })
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
end

return M
