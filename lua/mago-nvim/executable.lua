local M = {}

M.mago_path = nil

function M.init()
  local vendor_mago = vim.fn.findfile('vendor/bin/mago', '.;')
  if vendor_mago ~= '' then
    local full_path = vim.fn.fnamemodify(vendor_mago, ':p')
    if vim.fn.executable(full_path) == 1 then
      M.mago_path = full_path
      return true
    end
  end

  if vim.fn.executable 'mago' == 1 then
    M.mago_path = 'mago'
    return true
  end

  return false
end

function M.run(cmd, opts)
  if opts == nil then
    opts = {}
  end
  table.insert(cmd, 1, M.mago_path)

  opts.text = true

  local result = vim.system(cmd, opts):wait()

  if result.stderr ~= '' then
    local err = vim.fn.trim(result.stderr)
    local level = err:match '^(%S+)'
    vim.notify('[mago.nvim] ' .. err, vim.log.levels[level] or vim.log.levels.ERROR)
  end

  return result.stdout
end

return M
