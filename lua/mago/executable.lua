local M = {}

-- Find mago executable
-- Returns: path to mago executable or nil
function M.find()
  local config = require('mago.config').get()

  -- 1. Check if custom path is set in config
  if config.mago_path then
    if vim.fn.executable(config.mago_path) == 1 then
      return config.mago_path
    else
      vim.notify(
        string.format('[mago.nvim] Custom mago_path is not executable: %s', config.mago_path),
        vim.log.levels.WARN
      )
      return nil
    end
  end

  -- 2. Check for vendor/bin/mago (Composer install)
  -- Search upward from current buffer's directory
  local vendor_mago = vim.fn.findfile('vendor/bin/mago', '.;')
  if vendor_mago ~= '' then
    local full_path = vim.fn.fnamemodify(vendor_mago, ':p')
    if vim.fn.executable(full_path) == 1 then
      return full_path
    end
  end

  -- 3. Check for global mago in PATH
  if vim.fn.executable 'mago' == 1 then
    return 'mago'
  end

  return nil
end

-- Get mago executable or show error
-- Returns: path to mago or nil (with notification)
function M.get_or_error()
  local mago_path = M.find()

  if not mago_path then
    vim.notify(
      '[mago.nvim] Mago executable not found.\n'
        .. 'Install it globally or via Composer in your project:\n'
        .. '  composer require --dev carthage/mago',
      vim.log.levels.ERROR
    )
    return nil
  end

  return mago_path
end

-- Get mago version
-- Returns: version string or nil
function M.get_version(mago_path)
  if not mago_path then
    return nil
  end

  local result = vim.system({ mago_path, '--version' }, { text = true }):wait()

  if result.code == 0 then
    -- Extract version from output (format may vary)
    local version = result.stdout:match '[%d%.]+' or result.stdout:gsub('\n', '')
    return version
  end

  return nil
end

return M
