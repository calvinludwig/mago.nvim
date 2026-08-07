local M = {}

M.mago_path = nil
M.config = {
  logging = {
    notify = true,
    write_to_log = false,
    log_file = nil,
    min_level = vim.log.levels.INFO,
  },
}

local function support()
  return require 'mago-nvim.support'
end

local function normalize_level(level, fallback)
  if type(level) == 'number' then
    return level
  end

  if type(level) ~= 'string' then
    return fallback
  end

  local key = level:upper()
  if key == 'WARNING' then
    key = 'WARN'
  elseif key == 'ERR' then
    key = 'ERROR'
  end

  return vim.log.levels[key] or fallback
end

local function parse_stderr_level(message)
  local token = message:match '^%s*[%[%({<]*([%a_]+)'
  if token == nil then
    return vim.log.levels.ERROR
  end

  return normalize_level(token, vim.log.levels.ERROR)
end

local function level_name(level)
  for name, value in pairs(vim.log.levels) do
    if value == level then
      return name
    end
  end

  return 'ERROR'
end

local function write_log(message, level)
  if not M.config.logging.write_to_log then
    return
  end

  local log_path = M.config.logging.log_file or (vim.fn.stdpath 'log' .. '/mago.nvim.log')
  local line = string.format('%s [%s] %s', os.date '%Y-%m-%d %H:%M:%S', level_name(level), message)

  pcall(vim.fn.writefile, { line }, log_path, 'a')
end

function M.setup(opts)
  opts = opts or {}
  M.config = vim.tbl_deep_extend('force', M.config, opts)
  M.config.logging.min_level = normalize_level(M.config.logging.min_level, vim.log.levels.ERROR)
end

function M.init()
  local vendor_mago = vim.fn.findfile('vendor/bin/mago', '.;')
  if vendor_mago ~= '' then
    local full_path = vim.fn.fnamemodify(vendor_mago, ':p')
    if vim.fn.executable(full_path) == 1 then
      M.mago_path = full_path
      return true
    end
  end

  if vim.fn.executable 'mago' == 1 then
    M.mago_path = 'mago'
    return true
  end

  return false
end

function M.run(cmd, opts)
  if opts == nil then
    opts = {}
  end

  local filepath = opts.filepath
  opts.filepath = nil

  if opts.cwd == nil and type(filepath) == 'string' and filepath ~= '' then
    opts.cwd = support().cwd_from_filepath(filepath)
  end

  table.insert(cmd, 1, M.mago_path)

  opts.text = true

  local result = vim.system(cmd, opts):wait()

  if result.stderr ~= '' then
    local err = vim.fn.trim(result.stderr)
    if err ~= '' then
      local level = parse_stderr_level(err)
      if level >= M.config.logging.min_level then
        if M.config.logging.notify then
          vim.notify('[mago.nvim] ' .. err, level)
        end
        write_log(err, level)
      end
    end
  end

  return result.stdout
end

return M
