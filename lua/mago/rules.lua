local M = {}

-- Cache for rules list
local rules_cache = nil

-- Fetch rules from mago
function M.fetch_rules()
  local executable = require 'mago.executable'
  local mago_path = executable.find()

  if not mago_path then
    return nil
  end

  -- Run mago lint --list-rules --json
  local result = vim.system({ mago_path, 'lint', '--list-rules', '--json' }, { text = true }):wait()

  if result.code == 0 and result.stdout then
    -- Parse JSON
    local success, rules = pcall(vim.json.decode, result.stdout)
    if success then
      rules_cache = rules
      return rules
    end
  end

  return nil
end

-- List all available rules
function M.list_rules()
  local rules = rules_cache or M.fetch_rules()

  if not rules then
    vim.notify('[mago.nvim] Failed to fetch rules', vim.log.levels.ERROR)
    return
  end

  -- Create a buffer to display rules
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
  vim.api.nvim_buf_set_option(buf, 'filetype', 'mago-rules')

  -- Format rules as lines
  local lines = { '=== Mago Linter Rules ===', '' }

  -- Handle different possible JSON structures
  local rule_list = rules.rules or rules
  if type(rule_list) == 'table' then
    for _, rule in ipairs(rule_list) do
      local code = rule.code or rule.name or 'unknown'
      local name = rule.name or ''
      local description = rule.description or ''

      if code ~= '' then
        table.insert(lines, string.format('[%s] %s', code, name))
        if description ~= '' then
          table.insert(lines, '  ' .. description)
        end
        table.insert(lines, '')
      end
    end
  end

  if #lines == 2 then
    table.insert(lines, 'No rules found')
  end

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)

  -- Open in split
  vim.cmd 'split'
  vim.api.nvim_win_set_buf(0, buf)
end

-- Explain a specific rule
function M.explain_rule(rule_code)
  if not rule_code or rule_code == '' then
    vim.notify('[mago.nvim] No rule code provided', vim.log.levels.WARN)
    return
  end

  local executable = require 'mago.executable'
  local mago_path = executable.find()

  if not mago_path then
    vim.notify('[mago.nvim] Mago executable not found', vim.log.levels.ERROR)
    return
  end

  -- Run mago lint --explain RULE_CODE
  local result = vim.system({ mago_path, 'lint', '--explain', rule_code }, { text = true }):wait()

  if result.code == 0 and result.stdout then
    -- Create buffer to display explanation
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
    vim.api.nvim_buf_set_option(buf, 'filetype', 'markdown')

    local lines = vim.split(result.stdout, '\n', { plain = true })
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.api.nvim_buf_set_option(buf, 'modifiable', false)

    -- Open in split
    vim.cmd 'split'
    vim.api.nvim_win_set_buf(0, buf)
  else
    vim.notify(
      string.format('[mago.nvim] Failed to explain rule %s: %s', rule_code, result.stderr or 'Unknown error'),
      vim.log.levels.ERROR
    )
  end
end

return M
