local M = {}

-- Setup function - configures the plugin
function M.setup(opts)
  local config = require 'mago.config'
  config.set(opts)

  -- Set up format on save if enabled
  if config.get().format_on_save then
    M.setup_format_on_save()
  end

  -- Set up lint on save if enabled
  if config.get().lint_on_save then
    M.setup_lint_on_save()
  end

  -- Setup LSP integrations (code actions)
  if config.get().enable_lsp_code_actions ~= false then
    require('mago.lsp').setup()
  end
end

-- Set up auto-format on save for PHP files
function M.setup_format_on_save()
  local group = vim.api.nvim_create_augroup('MagoFormat', { clear = true })

  vim.api.nvim_create_autocmd('BufWritePre', {
    pattern = '*.php',
    group = group,
    callback = function()
      require('mago.formatter').format_buffer(0)
    end,
    desc = 'Format PHP file with Mago before saving',
  })
end

-- Toggle format on save
function M.toggle_format_on_save()
  local config = require 'mago.config'
  local current = config.get().format_on_save

  config.options.format_on_save = not current

  if config.options.format_on_save then
    M.setup_format_on_save()
    vim.notify('[mago.nvim] Format on save enabled', vim.log.levels.INFO)
  else
    -- Clear the autocmd group
    vim.api.nvim_create_augroup('MagoFormat', { clear = true })
    vim.notify('[mago.nvim] Format on save disabled', vim.log.levels.INFO)
  end
end

-- Set up auto-lint on save for PHP files
function M.setup_lint_on_save()
  local group = vim.api.nvim_create_augroup('MagoLint', { clear = true })

  vim.api.nvim_create_autocmd('BufWritePost', {
    pattern = '*.php',
    group = group,
    callback = function(ev)
      require('mago.linter').lint_buffer(ev.buf)
    end,
    desc = 'Lint PHP file with Mago after saving',
  })
end

-- Toggle lint on save
function M.toggle_lint_on_save()
  local config = require 'mago.config'
  local current = config.get().lint_on_save

  config.options.lint_on_save = not current

  if config.options.lint_on_save then
    M.setup_lint_on_save()
    vim.notify('[mago.nvim] Lint on save enabled', vim.log.levels.INFO)
  else
    -- Clear the autocmd group
    vim.api.nvim_create_augroup('MagoLint', { clear = true })
    vim.notify('[mago.nvim] Lint on save disabled', vim.log.levels.INFO)
  end
end

return M
