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
    print('Format on save: ' .. tostring(config.format_on_save))
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
