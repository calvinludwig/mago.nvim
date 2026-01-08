-- Define user commands for mago.nvim

-- :MagoFormat - Format entire buffer
vim.api.nvim_create_user_command('MagoFormat', function()
  require('mago.formatter').format_buffer(0)
end, {
  desc = 'Format current buffer with Mago',
})

-- :MagoFormatRange - Format visual selection or range
vim.api.nvim_create_user_command('MagoFormatRange', function(opts)
  require('mago.formatter').format_range(0, opts.line1, opts.line2)
end, {
  range = true,
  desc = 'Format selected range with Mago',
})

-- :MagoInfo - Show plugin and Mago information
vim.api.nvim_create_user_command('MagoInfo', function()
  local exe = require 'mago.executable'
  local config = require('mago.config').get()
  local path = exe.find()

  if path then
    local version = exe.get_version(path)
    print '=== Mago.nvim Info ==='
    print('Mago path: ' .. path)
    print('Version: ' .. (version or 'unknown'))
    print ''
    print '--- Formatter ---'
    print('Format on save: ' .. tostring(config.format_on_save))
    print ''
    print '--- Linter ---'
    print('Lint on save: ' .. tostring(config.lint_on_save))
    print('Lint severity: ' .. config.lint_severity)

    -- Show diagnostic count for current buffer
    local ns = require('mago.linter').get_namespace()
    local bufnr = vim.api.nvim_get_current_buf()
    local diagnostics = vim.diagnostic.get(bufnr, { namespace = ns })
    print('Current buffer diagnostics: ' .. #diagnostics)
  else
    print '=== Mago.nvim Info ==='
    print 'Mago executable: NOT FOUND'
    print 'Install Mago globally or via Composer:'
    print '  composer require --dev carthage/mago'
  end
end, {
  desc = 'Show Mago information',
})

-- :MagoToggleFormatOnSave - Toggle format on save
vim.api.nvim_create_user_command('MagoToggleFormatOnSave', function()
  require('mago').toggle_format_on_save()
end, {
  desc = 'Toggle Mago format on save',
})

-- Linter commands

-- :MagoLint - Lint current buffer
vim.api.nvim_create_user_command('MagoLint', function()
  require('mago.linter').lint_buffer(0)
end, {
  desc = 'Lint current buffer with Mago',
})

-- :MagoLintFix - Lint with auto-fix
vim.api.nvim_create_user_command('MagoLintFix', function()
  require('mago.linter').lint_fix(0)
end, {
  desc = 'Lint current buffer with auto-fix',
})

-- :MagoClearDiagnostics - Clear linting diagnostics
vim.api.nvim_create_user_command('MagoClearDiagnostics', function()
  require('mago.linter').clear_diagnostics(0)
  vim.notify('[mago.nvim] Cleared diagnostics', vim.log.levels.INFO)
end, {
  desc = 'Clear Mago linting diagnostics for current buffer',
})

-- :MagoLintOnly - Lint with specific rules only
vim.api.nvim_create_user_command('MagoLintOnly', function(opts)
  local rules = vim.split(opts.args, ',', { plain = true, trimempty = true })

  -- Trim whitespace from each rule
  for i, rule in ipairs(rules) do
    rules[i] = vim.trim(rule)
  end

  require('mago.linter').lint_only(0, rules)
end, {
  nargs = '+',
  desc = 'Lint with specific rules only (comma-separated)',
})

-- :MagoListRules - List available linting rules
vim.api.nvim_create_user_command('MagoListRules', function()
  require('mago.rules').list_rules()
end, {
  desc = 'List available Mago linting rules',
})

-- :MagoExplainRule - Explain a specific rule
vim.api.nvim_create_user_command('MagoExplainRule', function(opts)
  local rule_code = opts.args
  if rule_code == '' then
    vim.notify('[mago.nvim] Usage: :MagoExplainRule <RULE_CODE>', vim.log.levels.WARN)
    return
  end
  require('mago.rules').explain_rule(rule_code)
end, {
  nargs = 1,
  desc = 'Explain a specific Mago linting rule',
})

-- :MagoToggleLintOnSave - Toggle lint on save
vim.api.nvim_create_user_command('MagoToggleLintOnSave', function()
  require('mago').toggle_lint_on_save()
end, {
  desc = 'Toggle Mago lint on save',
})
