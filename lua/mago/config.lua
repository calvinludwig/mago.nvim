local M = {}

-- Default configuration
M.defaults = {
  -- Formatter
  format_on_save = false, -- Auto-format on save

  -- Linter
  lint_on_save = false, -- Auto-lint on save

  -- LSP Integration
  enable_lsp_code_actions = true, -- Enable code actions integration

  -- Shared
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
