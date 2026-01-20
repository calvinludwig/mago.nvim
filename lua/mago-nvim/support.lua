local M = {}

function M.uri_to_relative_fname(uri)
  local fname = vim.uri_to_fname(uri)
  local root = vim.fs.root(0, { '.git', 'composer.json' }) or vim.fn.getcwd()
  local relative = vim.fn.fnamemodify(fname, ':p'):sub(#root + 2)

  return relative
end

return M
