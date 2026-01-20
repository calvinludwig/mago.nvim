vim.api.nvim_create_user_command('MagoFormat', function()
  vim.lsp.buf.format { async = true }
end, {
  desc = 'Format current buffer with Mago',
})

vim.api.nvim_create_user_command('MagoLintFix', function()
  require('mago-nvim.server.fixer').fix(0)
end, {
  desc = 'Fix all linting errors in the current buffer with Mago',
})

vim.api.nvim_create_user_command('MagoExplainRule', function(opts)
  local rule = vim.fn.trim(opts.args)

  if rule == '' then
    vim.notify('[mago.nvim] Specify rule by parameter (:MagoExplainRule <rule>)', vim.log.levels.INFO)
    return
  end

  require('mago-nvim.server.rules').popup_explain(rule)
end, {
  nargs = '?',
  desc = 'Explain a Mago linter rule',
})
