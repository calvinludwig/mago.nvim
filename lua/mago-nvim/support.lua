local M = {}

function M.cwd_from_filepath(filepath)
  if type(filepath) ~= 'string' or filepath == '' then
    return vim.fn.getcwd()
  end

  local absolute = vim.fn.fnamemodify(filepath, ':p')
  local root = vim.fs.root(absolute, { '.git', 'composer.json' })

  if root and root ~= '' then
    return root
  end

  return vim.fn.fnamemodify(absolute, ':h')
end

function M.uri_to_relative_fname(uri)
  local fname = vim.uri_to_fname(uri)
  if type(fname) ~= 'string' or fname == '' then
    return ''
  end

  local absolute = vim.fn.fnamemodify(fname, ':p')
  local root = M.cwd_from_filepath(absolute)
  local prefix = root .. '/'

  if absolute:sub(1, #prefix) == prefix then
    return absolute:sub(#prefix + 1)
  end

  return vim.fn.fnamemodify(absolute, ':t')
end

return M
