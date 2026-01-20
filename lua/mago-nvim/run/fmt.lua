local M = {}

local function mago()
  return require 'mago-nvim.executable'
end

function M.format_filepath(filepath)
  --
  mago().run { 'fmt', filepath }
end

function M.format_stdin(input)
  --
  return mago().run({ 'fmt', '--stdin-input' }, { stdin = input })
end

return M
