local M = {}

-- LSP-compatible formatting function
-- This can be used with vim.lsp.buf.format() and other LSP formatting tools
function M.format(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  return require('mago.formatter').format_buffer(bufnr)
end

-- Register Mago as an LSP-compatible formatter
-- This allows it to work with vim.lsp.buf.format() and other LSP tools
function M.setup()
  -- Setup code actions provider
  require('mago.code_actions').setup()

  -- Note: For direct vim.lsp.buf.format() integration, users should configure
  -- their LSP client to use Mago as the formatter
end

return M
