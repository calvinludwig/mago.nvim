local M = {}

local function mago()
  return require 'mago-nvim.executable'
end

function M.format_filepath(filepath)
  --
  mago().run({ 'fmt', filepath }, {
    filepath = filepath,
  })
end

function M.format_stdin(input, filepath)
  --
  return mago().run({ 'fmt', '--stdin-input' }, {
    stdin = input,
    filepath = filepath,
  })
end

return M
