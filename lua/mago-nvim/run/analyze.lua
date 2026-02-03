local M = {}

local function mago()
  return require 'mago-nvim.executable'
end

function M.check(filepath)
  local output = mago().run { 'analyze', '--reporting-format', 'json', filepath }
  if output == nil or output == '' then
    return {}
  end
  local decoded = vim.json.decode(output)
  return decoded.issues
end

function M.list_files()
  return mago().run { 'list-files', '--command', 'analyzer' }
end

return M
