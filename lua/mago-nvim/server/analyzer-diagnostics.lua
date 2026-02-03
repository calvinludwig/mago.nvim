local M = {}

local severity_map = {
  Error = vim.diagnostic.severity.ERROR,
  Warning = vim.diagnostic.severity.WARN,
  Help = vim.diagnostic.severity.HINT,
  Note = vim.diagnostic.severity.INFO,
}

local function get_range_from_span(span, bufnr)
  local start_line = span.start.line
  local end_line = span['end'].line
  local start_character = span.start.offset - vim.api.nvim_buf_get_offset(bufnr, start_line)
  local end_character = span['end'].offset - vim.api.nvim_buf_get_offset(bufnr, end_line)

  return {
    ['start'] = { line = start_line, character = start_character },
    ['end'] = { line = end_line, character = end_character },
  }
end

local function convert_issue_to_diagnostic(issue, bufnr)
  local span = issue.annotations[1].span

  return {
    range = get_range_from_span(span, bufnr),
    severity = severity_map[issue.level],
    message = string.format('[%s] %s', issue.code, issue.message),
    codeDescription = issue.code,
    source = "Mago's analyzer",
  }
end

local function get_diagnostics_from_mago_issues(issues, bufnr)
  local diagnostics = vim.tbl_map(function(issue)
    return convert_issue_to_diagnostic(issue, bufnr)
  end, issues or {})
  return diagnostics
end

local function uri_can_be_analyzed(uri)
  local relative_filepath = require('mago-nvim.support').uri_to_relative_fname(uri)
  local files = vim.split(require('mago-nvim.run.analyze').list_files(), '\n')

  return vim.tbl_contains(files, relative_filepath)
end

function M.get_diagnostics(uri)
  if not uri_can_be_analyzed(uri) then
    return {}
  end

  local filepath = vim.uri_to_fname(uri)
  local bufnr = vim.uri_to_bufnr(uri)
  local issues = require('mago-nvim.run.analyze').check(filepath)

  return get_diagnostics_from_mago_issues(issues, bufnr)
end

return M
