local M = {}

-- Cache of fixable rules (populated once per session)
local fixable_rules_cache = nil

-- Track attached clients per buffer to avoid duplicates
local attached_buffers = {}

-- Fetch and cache fixable rules from mago
function M.get_fixable_rules()
  -- Return cached result if available
  if fixable_rules_cache then
    return fixable_rules_cache
  end

  local executable = require 'mago.executable'
  local mago_path = executable.find()

  if not mago_path then
    return nil
  end

  -- Run: mago lint --list-rules --json
  local result = vim.system({ mago_path, 'lint', '--list-rules', '--json' }, { text = true }):wait()

  if result.code ~= 0 or not result.stdout then
    return nil
  end

  -- Parse JSON
  local success, rules_data = pcall(vim.json.decode, result.stdout)
  if not success then
    return nil
  end

  -- Build lookup table: { rule_code -> rule } for all rules
  -- Note: For now, we'll assume all rules are potentially fixable
  -- since mago doesn't explicitly mark fixability in the JSON
  local fixable = {}
  local rules_list = rules_data.rules or rules_data

  for _, rule in ipairs(rules_list) do
    local code = rule.code or rule.name
    if code then
      fixable[code] = true
    end
  end

  -- Cache for session
  fixable_rules_cache = fixable

  return fixable
end

-- Get mago diagnostics at cursor position
function M.get_diagnostics_at_cursor(bufnr, line, col)
  local linter_ns = require('mago.linter').get_namespace()
  local all_diagnostics = vim.diagnostic.get(bufnr, { namespace = linter_ns })

  -- Filter to diagnostics that overlap the cursor line
  local cursor_diagnostics = {}
  for _, diag in ipairs(all_diagnostics) do
    if diag.lnum == line then
      table.insert(cursor_diagnostics, diag)
    end
  end

  return cursor_diagnostics
end

-- Get unique rule codes from diagnostics
local function get_unique_rule_codes(diagnostics)
  local seen = {}
  local unique = {}

  for _, diag in ipairs(diagnostics) do
    if diag.code and not seen[diag.code] then
      seen[diag.code] = true
      table.insert(unique, diag.code)
    end
  end

  return unique
end

-- Group diagnostics by severity level
local function group_diagnostics_by_severity(diagnostics)
  local groups = {
    [vim.diagnostic.severity.ERROR] = {},
    [vim.diagnostic.severity.WARN] = {},
    [vim.diagnostic.severity.INFO] = {},
    [vim.diagnostic.severity.HINT] = {},
  }

  for _, diag in ipairs(diagnostics) do
    if diag.code and diag.severity then
      table.insert(groups[diag.severity], diag)
    end
  end

  return groups
end

-- Count diagnostics that match any of the given rule codes
local function count_diagnostics_with_codes(diagnostics, rule_codes)
  local code_set = {}
  for _, code in ipairs(rule_codes) do
    code_set[code] = true
  end

  local count = 0
  for _, diag in ipairs(diagnostics) do
    if diag.code and code_set[diag.code] then
      count = count + 1
    end
  end

  return count
end

-- Generate code actions for current context
function M.get_code_actions(bufnr, range)
  local actions = {}
  local filepath = vim.api.nvim_buf_get_name(bufnr)

  -- Check if file is saved
  if filepath == '' or vim.fn.filereadable(filepath) ~= 1 then
    return {} -- File must be saved to apply fixes
  end

  -- Get mago diagnostics for the buffer
  local linter_ns = require('mago.linter').get_namespace()
  local all_diagnostics = vim.diagnostic.get(bufnr, { namespace = linter_ns })

  if #all_diagnostics == 0 then
    return {} -- No diagnostics, no actions
  end

  -- Get diagnostics at cursor (within range)
  local cursor_diagnostics = {}
  for _, diag in ipairs(all_diagnostics) do
    if diag.lnum >= range.start.line and diag.lnum <= range['end'].line then
      table.insert(cursor_diagnostics, diag)
    end
  end

  -- 1. Individual rule fixes at cursor
  local added_rules = {} -- Track which rules we've already added actions for
  for _, diag in ipairs(cursor_diagnostics) do
    if diag.code and not added_rules[diag.code] then
      local message = diag.message or ''
      -- Remove the [CODE] prefix if it exists in the message
      local clean_message = message:gsub('^%[.-%]%s*', '')
      -- Truncate message if too long
      if #clean_message > 50 then
        clean_message = clean_message:sub(1, 47) .. '...'
      end

      table.insert(actions, {
        title = string.format('Fix [%s]: %s', diag.code, clean_message),
        kind = 'quickfix',
        command = {
          title = 'Fix with Mago',
          command = 'mago.apply_fix',
          arguments = { bufnr, diag.code, filepath },
        },
      })

      added_rules[diag.code] = true
    end
  end

  -- 2. Fix all rules at cursor (if multiple unique rules)
  local cursor_rule_codes = get_unique_rule_codes(cursor_diagnostics)
  if #cursor_rule_codes > 1 then
    table.insert(actions, {
      title = string.format('Fix all issues at cursor (%d rule%s)', #cursor_rule_codes, #cursor_rule_codes == 1 and '' or 's'),
      kind = 'quickfix',
      command = {
        title = 'Fix all at cursor with Mago',
        command = 'mago.apply_fix',
        arguments = { bufnr, cursor_rule_codes, filepath },
      },
    })
  end

  -- 3. Fix by severity groups
  local severity_groups = group_diagnostics_by_severity(all_diagnostics)
  local severity_names = {
    [vim.diagnostic.severity.ERROR] = 'errors',
    [vim.diagnostic.severity.WARN] = 'warnings',
    [vim.diagnostic.severity.INFO] = 'info',
    [vim.diagnostic.severity.HINT] = 'hints',
  }

  -- Sort severities: ERROR, WARN, INFO, HINT
  local severity_order = {
    vim.diagnostic.severity.ERROR,
    vim.diagnostic.severity.WARN,
    vim.diagnostic.severity.INFO,
    vim.diagnostic.severity.HINT,
  }

  for _, severity in ipairs(severity_order) do
    local diags = severity_groups[severity]
    if #diags > 0 then
      local unique_codes = get_unique_rule_codes(diags)
      if #unique_codes > 0 then
        local issue_count = #diags
        table.insert(actions, {
          title = string.format(
            'Fix all %s (%d issue%s, %d rule%s)',
            severity_names[severity],
            issue_count,
            issue_count == 1 and '' or 's',
            #unique_codes,
            #unique_codes == 1 and '' or 's'
          ),
          kind = 'quickfix',
          command = {
            title = string.format('Fix all %s with Mago', severity_names[severity]),
            command = 'mago.apply_fix',
            arguments = { bufnr, unique_codes, filepath },
          },
        })
      end
    end
  end

  -- 4. Fix all issues
  local issue_count = #all_diagnostics
  table.insert(actions, {
    title = string.format('Fix all issues with Mago (%d issue%s)', issue_count, issue_count == 1 and '' or 's'),
    kind = 'quickfix',
    command = {
      title = 'Fix all with Mago',
      command = 'mago.apply_fix',
      arguments = { bufnr, nil, filepath }, -- nil = fix all
    },
  })

  return actions
end

-- Apply a fix action
-- @param bufnr number: Buffer number
-- @param rule_codes nil|string|table: Rule code(s) to fix (nil = fix all, string = single rule, table = multiple rules)
-- @param filepath string: Path to the file
function M.apply_fix(bufnr, rule_codes, filepath)
  local executable = require 'mago.executable'
  local mago_path = executable.find()

  if not mago_path then
    vim.notify('[mago.nvim] Mago executable not found', vim.log.levels.ERROR)
    return
  end

  -- Build command (note: --fix cannot be used with --reporting-format)
  local cmd = { mago_path, 'lint', '--fix' }

  if rule_codes then
    table.insert(cmd, '--only')

    if type(rule_codes) == 'string' then
      -- Single rule
      table.insert(cmd, rule_codes)
      vim.notify(string.format('[mago.nvim] Fixing rule: %s...', rule_codes), vim.log.levels.INFO)
    elseif type(rule_codes) == 'table' then
      -- Multiple rules: join with commas
      local rules_str = table.concat(rule_codes, ',')
      table.insert(cmd, rules_str)
      vim.notify(
        string.format('[mago.nvim] Fixing %d rule%s...', #rule_codes, #rule_codes == 1 and '' or 's'),
        vim.log.levels.INFO
      )
    end
  else
    -- Fix all
    vim.notify('[mago.nvim] Fixing all issues...', vim.log.levels.INFO)
  end

  table.insert(cmd, filepath)

  -- Execute fix
  local result = vim.system(cmd, { text = true }):wait()

  if result.code == 0 or (result.code == 1 and result.stdout) then
    -- Reload buffer to show changes
    vim.api.nvim_buf_call(bufnr, function()
      vim.cmd 'checktime'
    end)

    -- Clear old diagnostics
    local linter = require 'mago.linter'
    linter.clear_diagnostics(bufnr)

    -- Re-lint after a short delay
    vim.defer_fn(function()
      linter.lint_buffer(bufnr)
      vim.notify('[mago.nvim] Fix applied successfully', vim.log.levels.INFO)
    end, 100)
  else
    vim.notify(
      string.format('[mago.nvim] Fix failed: %s', result.stderr or 'Unknown error'),
      vim.log.levels.ERROR
    )
  end
end

-- Minimal LSP server implementation
local function create_mago_lsp_server()
  local server = {}
  local closing = false

  function server.request(method, params, callback)
    if method == 'initialize' then
      callback(nil, {
        capabilities = {
          codeActionProvider = true,
        },
      })
    elseif method == 'textDocument/codeAction' then
      local bufnr = vim.uri_to_bufnr(params.textDocument.uri)
      local actions = M.get_code_actions(bufnr, params.range)
      callback(nil, actions)
    elseif method == 'shutdown' then
      closing = true
      callback(nil, nil)
    else
      callback(nil, nil)
    end
  end

  function server.notify(method, params)
    -- Stub for notifications
  end

  function server.is_closing()
    return closing
  end

  function server.terminate()
    -- Cleanup
    closing = true
  end

  return server
end

-- Attach code action provider to buffer
function M.attach_to_buffer(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  -- Avoid attaching multiple times
  if attached_buffers[bufnr] then
    return attached_buffers[bufnr]
  end

  -- Only attach to PHP files
  if vim.bo[bufnr].filetype ~= 'php' then
    return nil
  end

  -- Start the minimal LSP client
  local client_id = vim.lsp.start {
    name = 'mago-code-actions',
    cmd = create_mago_lsp_server,
    root_dir = vim.fn.getcwd(),
  }

  if client_id then
    attached_buffers[bufnr] = client_id

    -- Clean up on buffer delete
    vim.api.nvim_create_autocmd('BufDelete', {
      buffer = bufnr,
      once = true,
      callback = function()
        attached_buffers[bufnr] = nil
      end,
    })
  end

  return client_id
end

-- Setup function (called from init.lua or lsp.lua)
function M.setup()
  -- Register command handler for LSP commands
  vim.lsp.commands['mago.apply_fix'] = function(command)
    local args = command.arguments
    M.apply_fix(unpack(args))
  end

  -- Register autocmd to attach on PHP files
  vim.api.nvim_create_autocmd('FileType', {
    pattern = 'php',
    group = vim.api.nvim_create_augroup('MagoCodeActions', { clear = true }),
    callback = function(ev)
      M.attach_to_buffer(ev.buf)
    end,
  })
end

return M
