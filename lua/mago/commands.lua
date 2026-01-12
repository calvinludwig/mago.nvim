-- :MagoInfo - Show plugin and Mago information
vim.api.nvim_create_user_command('MagoInfo', function()
  local exe = require 'mago.executable'
  local path = exe.find()

  if path then
    local version = exe.get_version(path)
    print '=== Mago.nvim Info ==='
    print('Mago path: ' .. path)
    print('Version: ' .. (version or 'unknown'))

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

-- :MagoFixAll - Fix all linting errors in the current buffer
vim.api.nvim_create_user_command('MagoFixAll', function() require('mago.linter').fix_all(0) end, {
  desc = 'Fix all linting errors in the current buffer with Mago',
})

-- :MagoExplainRule [rule] - Show detailed explanation of a linter rule
vim.api.nvim_create_user_command('MagoExplainRule', function(opts)
  local linter = require 'mago.linter'
  local rule_code = opts.args
  
  -- If no argument provided, try to get rule from cursor position
  if rule_code == '' then
    local bufnr = vim.api.nvim_get_current_buf()
    rule_code = linter.get_rule_at_cursor(bufnr)
    
    if not rule_code then
      vim.notify(
        '[mago.nvim] No diagnostic found at cursor. Specify rule by parameter (:MagoExplainRule <rule>) or place cursor on a diagnostic',
        vim.log.levels.INFO
      )
      return
    end
  end
  
  -- Show explanation in floating window
  linter.show_rule_explanation(rule_code)
end, {
  nargs = '?',
  desc = 'Explain a Mago linter rule (uses cursor diagnostic if no arg provided)',
})
