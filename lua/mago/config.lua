local M = {}

-- Default configuration
M.defaults = {
  format_on_save = false, -- Auto-format on save
  mago_path = nil, -- Custom mago path (nil = auto-detect)
  notify_on_error = true, -- Show vim.notify on error
  quickfix_on_error = true, -- Populate quickfix on error
}

-- Current configuration (will be set by init.setup())
M.options = vim.deepcopy(M.defaults)

-- Set configuration by merging user options with defaults
function M.set(opts)
  M.options = vim.tbl_deep_extend('force', M.defaults, opts or {})
end

-- Get current configuration
function M.get()
  return M.options
end

return M
