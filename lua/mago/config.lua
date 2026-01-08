local M = {}

-- Default configuration
M.defaults = {
  format_on_save = true, -- Auto-format on save
  lint_on_save = true, -- Auto-lint on save
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
