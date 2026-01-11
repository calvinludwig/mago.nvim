local ns = vim.api.nvim_create_namespace 'mago_linter'

local severity_map = {
  error = vim.diagnostic.severity.ERROR,
  warning = vim.diagnostic.severity.WARN,
  help = vim.diagnostic.severity.HINT,
  note = vim.diagnostic.severity.INFO,
}

local function normalize_bufnr(bufnr) return bufnr or vim.api.nvim_get_current_buf() end

local function validate_php_buffer(bufnr)
  if vim.bo[bufnr].filetype ~= 'php' then return false end
  return true
end

local function validate_saved_filepath(bufnr)
  local filepath = vim.api.nvim_buf_get_name(bufnr)
  if filepath == '' or vim.fn.filereadable(filepath) ~= 1 then
    vim.notify('[mago.nvim] Buffer must be saved to disk before linting', vim.log.levels.WARN)
    return nil
  end
  return filepath
end

local function get_mago_executable() return require('mago.executable').get_or_error() end

local function parse_json_output(json_output)
  if not json_output or json_output == '' then return {} end

  local success, data = pcall(vim.json.decode, json_output)
  if not success then
    vim.notify('[mago.nvim] Failed to parse linter output', vim.log.levels.ERROR)
    return nil
  end

  return data
end

local function extract_issues_array(data)
  local issues = data.diagnostics or data.issues or data
  if type(issues) ~= 'table' then return {} end
  return issues
end

local function find_primary_annotation(annotations)
  for _, ann in ipairs(annotations) do
    if ann.kind == 'Primary' then return ann end
  end
  return annotations[1]
end

local function calculate_column_from_offset(bufnr, line_num, start_offset)
  local col = 0
  if line_num > 0 then
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, line_num, false)
    if #lines >= line_num then
      local line_start_offset = 0
      for i = 1, line_num - 1 do
        line_start_offset = line_start_offset + #lines[i] + 1
      end
      col = start_offset - line_start_offset
      if col < 0 then col = 0 end
    end
  end
  return col
end

local function extract_location_from_span(span, bufnr)
  local start_pos = span.start or {}
  local end_pos = span['end'] or {}
  local line_num = start_pos.line or 1
  local start_offset = start_pos.offset or 0

  local col = calculate_column_from_offset(bufnr, line_num, start_offset)

  return {
    line_num = line_num,
    col = col,
    end_line = end_pos.line or line_num,
  }
end

local function build_diagnostic_message(issue)
  local message = issue.message or 'Unknown issue'
  local rule_code = issue.code
  if rule_code then return string.format('[%s] %s', rule_code, message), rule_code end
  return message, rule_code
end

local function should_include_diagnostic(diag_filepath, buf_filepath)
  return diag_filepath == '' or diag_filepath == buf_filepath
end

local function create_diagnostic_entry(bufnr, issue, location, message, rule_code, severity_str)
  return {
    bufnr = bufnr,
    lnum = location.line_num,
    col = location.col,
    end_lnum = location.end_line,
    end_col = -1,
    severity = severity_map[severity_str] or vim.diagnostic.severity.INFO,
    message = message,
    source = 'mago',
    code = rule_code,
  }
end

local function process_issue_to_diagnostic(issue, bufnr, buf_filepath)
  local severity_str = string.lower(issue.level)
  local annotations = issue.annotations or {}
  local primary_annotation = find_primary_annotation(annotations)

  if not primary_annotation then return nil end

  local span = primary_annotation.span or {}
  local file_id = span.file_id or {}
  local diag_filepath = file_id.path or ''

  if not should_include_diagnostic(diag_filepath, buf_filepath) then return nil end

  local location = extract_location_from_span(span, bufnr)
  local message, rule_code = build_diagnostic_message(issue)

  return create_diagnostic_entry(bufnr, issue, location, message, rule_code, severity_str)
end

local function process_and_set_diagnostics(stdout, bufnr)
  if not stdout or stdout == '' then return false end

  local data = parse_json_output(stdout)
  if not data then return false end

  local issues = extract_issues_array(data)
  local buf_filepath = vim.api.nvim_buf_get_name(bufnr)
  local diagnostics = {}

  for _, issue in ipairs(issues) do
    local diagnostic = process_issue_to_diagnostic(issue, bufnr, buf_filepath)
    if diagnostic then table.insert(diagnostics, diagnostic) end
  end

  vim.diagnostic.set(ns, bufnr, diagnostics, {})
  return diagnostics
end

local function notify_diagnostic_results(count, custom_message)
  if custom_message then
    vim.notify(custom_message, vim.log.levels.INFO)
  elseif count > 0 then
    vim.notify(string.format('[mago.nvim] Found %d issue(s)', count), vim.log.levels.INFO)
  else
    vim.notify('[mago.nvim] No issues found', vim.log.levels.INFO)
  end
end

local function handle_lint_error(result)
  if result.code ~= 0 and result.stderr and result.stderr ~= '' then
    vim.notify(string.format('[mago.nvim] Linting failed: %s', result.stderr), vim.log.levels.ERROR)
  end
  return false
end

local function reload_buffer(bufnr)
  vim.api.nvim_buf_call(bufnr, function() vim.cmd 'checktime' end)
end

local function apply_fixes_and_relint(bufnr, M)
  reload_buffer(bufnr)
  M.clear_diagnostics(bufnr)
  vim.notify('[mago.nvim] Applied auto-fixes, re-linting...', vim.log.levels.INFO)
  vim.defer_fn(function() M.lint_buffer(bufnr) end, 100)
end

local M = {}

function M.get_namespace() return ns end

function M.parse_diagnostics(json_output, bufnr)
  local data = parse_json_output(json_output)
  if not data then return nil end

  local issues = extract_issues_array(data)
  local buf_filepath = vim.api.nvim_buf_get_name(bufnr)
  local diagnostics = {}

  for _, issue in ipairs(issues) do
    local diagnostic = process_issue_to_diagnostic(issue, bufnr, buf_filepath)
    if diagnostic then table.insert(diagnostics, diagnostic) end
  end

  return diagnostics
end

function M.clear_linting(bufnr) vim.diagnostic.reset(ns, normalize_bufnr(bufnr)) end

function M.lint(bufnr)
  bufnr = normalize_bufnr(bufnr)

  if not validate_php_buffer(bufnr) then return false end

  local filepath = validate_saved_filepath(bufnr)
  if not filepath then return false end

  local mago_path = get_mago_executable()
  if not mago_path then return false end

  local cmd = { mago_path, 'lint', '--reporting-format', 'json', filepath }
  local result = vim.system(cmd, { text = true }):wait()

  local diagnostics = process_and_set_diagnostics(result.stdout, bufnr)
  if diagnostics then
    notify_diagnostic_results(#diagnostics)
    return true
  end

  return handle_lint_error(result)
end

function M.clear_diagnostics(bufnr) vim.diagnostic.reset(ns, normalize_bufnr(bufnr)) end

function M.fix_errors(bufnr)
  bufnr = normalize_bufnr(bufnr)

  if not validate_php_buffer(bufnr) then return false end

  local filepath = validate_saved_filepath(bufnr)
  if not filepath then return false end

  local mago_path = get_mago_executable()
  if not mago_path then return false end

  local cmd = { mago_path, 'lint', '--fix', filepath }
  local result = vim.system(cmd, { text = true }):wait()

  if result.code == 0 or (result.code == 1 and result.stdout) then
    apply_fixes_and_relint(bufnr, M)
    return true
  end

  vim.notify(string.format('[mago.nvim] Auto-fix failed: %s', result.stderr or 'Unknown error'), vim.log.levels.ERROR)
  return false
end

return M
