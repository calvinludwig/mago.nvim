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

-- :MagoFormat - Format entire buffer
vim.api.nvim_create_user_command('MagoFormat', function() require('mago.formatter').format_buffer(0) end, {
  desc = 'Format current buffer with Mago',
})

-- :MagoListRules - List available linting rules
vim.api.nvim_create_user_command('MagoListRules', function() require('mago.rules').list_rules() end, {
  desc = 'List available Mago linting rules',
})

-- :MagoFixLintErrors - Fix linting errors in the current buffer
vim.api.nvim_create_user_command('MagoFixLintErrors', function() require('mago.linter').fix_lint_errors(0) end, {
  desc = 'Fix linting errors in the current buffer with Mago',
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
