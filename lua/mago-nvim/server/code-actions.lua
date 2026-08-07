local M = {}

local function get_rule_code(diag)
  return (diag.user_data and diag.user_data.lsp and diag.user_data.lsp.codeDescription)
    or diag.codeDescription
    or diag.code
end

local function get_issue(d)
  return {
    line = d.lnum + 1,
    code = get_rule_code(d),
  }
end

local function get_issues_from_buffer(bufnr)
  local contains_parse_issue = false

  local diagnostics = vim.tbl_filter(function(diag)
    local code = get_rule_code(diag)

    if code == 'parse' then
      contains_parse_issue = true
    end

    return diag.source == 'mago.nvim' and code ~= nil
  end, vim.diagnostic.get(bufnr))

  if contains_parse_issue == true then
    vim.notify('[mago.nvim] Fix parse errors first', vim.log.levels.ERROR)
    return {}
  end

  return vim.tbl_filter(function(issue)
    return issue.code ~= nil
  end, vim.tbl_map(get_issue, diagnostics or {}))
end

local function issues_to_list(issues)
  local seen = {}
  local list = {}

  for _, item in ipairs(issues) do
    if not seen[item.code] then
      seen[item.code] = true
      table.insert(list, item.code)
    end
  end

  return list
end

function M.retrieve_from_buffer(bufnr)
  if vim.bo[bufnr].filetype ~= 'php' then
    return {}
  end

  local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
  local actions = {}

  local issues = get_issues_from_buffer(bufnr)
  local current_line_issues = vim.tbl_filter(function(l)
    return l.line == cursor_line
  end, issues)
  local other_issues = vim.tbl_filter(function(l)
    return l.line ~= cursor_line
  end, issues)

  local current_line_list = issues_to_list(current_line_issues)
  local other_line_list = vim.tbl_filter(function(x)
    return vim.tbl_contains(current_line_list, x) == false
  end, issues_to_list(other_issues))

  for _, item in ipairs(current_line_list) do
    table.insert(actions, {
      title = string.format('Explain [%s] rule', item),
      kind = 'quickfix',
      command = {
        title = string.format('Explain [%s] rule', item),
        command = 'mago.explain_rule',
        arguments = { item },
      },
    })
    table.insert(actions, {
      title = string.format('Fix [%s] issues', item),
      kind = 'quickfix',
      command = {
        title = string.format('Fix [%s] issues', item),
        command = 'mago.fix_rule',
        arguments = { bufnr, item },
      },
    })
  end

  for _, item in ipairs(other_line_list) do
    table.insert(actions, {
      title = string.format('Fix [%s] issues', item),
      kind = 'quickfix',
      command = {
        title = string.format('Fix [%s] issues', item),
        command = 'mago.fix_rule',
        arguments = { bufnr, item },
      },
    })
  end

  if next(issues) ~= nil then
    table.insert(actions, {
      title = 'Fix all Mago issues in file',
      kind = 'quickfix',
      command = {
        title = 'Fix all Mago issues',
        command = 'mago.fix_all',
        arguments = { bufnr },
      },
    })
  end

  return actions
end

return M
