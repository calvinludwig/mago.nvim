local M = {}

local function mago()
  return require 'mago-nvim.executable'
end

function M.check(filepath)
  local output = mago().run { 'lint', '--reporting-format', 'json', filepath }
  if output == nil or output == '' then
    return {}
  end
  local decoded = vim.json.decode(output)
  return decoded.issues
end

function M.explain(rule)
  --
  return mago().run { 'lint', '--explain', rule }
end

function M.fix(filepath, rule)
  local cmd = { 'lint', '--fix', filepath, '--format-after-fix' }

  if rule ~= nil then
    table.insert(cmd, '--only')
    table.insert(cmd, rule)
  end

  return mago().run(cmd)
end

return M
