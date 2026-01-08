local M = {}

-- Namespace for diagnostics
local ns = vim.api.nvim_create_namespace 'mago_linter'

-- Get diagnostic namespace (public for external clearing)
function M.get_namespace()
  return ns
end

-- Severity mapping from Mago to Neovim
local severity_map = {
  error = vim.diagnostic.severity.ERROR,
  warning = vim.diagnostic.severity.WARN,
  info = vim.diagnostic.severity.INFO,
  hint = vim.diagnostic.severity.HINT,
}

-- Check if diagnostic meets severity threshold
local function meets_severity_threshold(diagnostic_severity, min_severity)
  local levels = { error = 1, warning = 2, info = 3, hint = 4 }

  -- Default to hint if severity not recognized
  local diag_level = levels[diagnostic_severity] or 4
  local min_level = levels[min_severity] or 4

  return diag_level <= min_level
end

-- Parse JSON output from mago lint
-- Returns: array of vim.diagnostic items or nil on error
function M.parse_diagnostics(json_output, bufnr)
  if not json_output or json_output == '' then
    return {}
  end

  -- Parse JSON
  local success, data = pcall(vim.json.decode, json_output)
  if not success then
    vim.notify('[mago.nvim] Failed to parse linter output', vim.log.levels.ERROR)
    return nil
  end

  -- Debug: Show the JSON structure (temporary)
  -- vim.notify('[mago.nvim DEBUG] JSON structure: ' .. vim.inspect(data), vim.log.levels.INFO)

  local config = require('mago.config').get()
  local diagnostics = {}

  -- Handle different possible JSON structures
  local issues = data.diagnostics or data.issues or data
  if type(issues) ~= 'table' then
    return {}
  end

  -- Get the buffer's file path for verification
  local buf_filepath = vim.api.nvim_buf_get_name(bufnr)

  for _, issue in ipairs(issues) do
    -- Map Mago severity levels to lowercase
    -- Mago uses: "Help", "Warning", "Error", etc.
    local level_map = {
      Help = 'hint',
      Warning = 'warning',
      Error = 'error',
      Info = 'info',
    }
    local severity_str = level_map[issue.level] or (issue.level or 'hint'):lower()

    if meets_severity_threshold(severity_str, config.lint_severity) then
      -- Get primary annotation for location info
      local annotations = issue.annotations or {}
      local primary_annotation = nil
      for _, ann in ipairs(annotations) do
        if ann.kind == 'Primary' then
          primary_annotation = ann
          break
        end
      end

      -- Fall back to first annotation if no primary found
      primary_annotation = primary_annotation or annotations[1]

      if primary_annotation then
        -- Extract location from annotation span
        local span = primary_annotation.span or {}
        local file_id = span.file_id or {}
        local diag_filepath = file_id.path or ''

        -- Only add diagnostic if it's for the current buffer's file
        if diag_filepath == '' or diag_filepath == buf_filepath then
          local start_pos = span.start or {}
          local end_pos = span['end'] or {}

          -- Calculate column from byte offset
          local line_num = start_pos.line or 1
          local start_offset = start_pos.offset or 0

          -- Get the actual line from buffer to calculate column
          local col = 0
          if line_num > 0 then
            -- Get all lines up to the diagnostic line
            local lines = vim.api.nvim_buf_get_lines(bufnr, 0, line_num, false)
            if #lines >= line_num then
              -- Calculate byte offset of the line start
              local line_start_offset = 0
              for i = 1, line_num - 1 do
                line_start_offset = line_start_offset + #lines[i] + 1 -- +1 for newline
              end
              -- Column is the difference between diagnostic offset and line start
              col = start_offset - line_start_offset
              if col < 0 then
                col = 0
              end
            end
          end

          -- Build diagnostic message with rule code
          local message = issue.message or 'Unknown issue'
          local rule_code = issue.code
          if rule_code then
            message = string.format('[%s] %s', rule_code, message)
          end

          -- Create diagnostic entry
          -- Note: Mago's JSON uses 0-indexed line numbers (same as Neovim)
          local diagnostic = {
            bufnr = bufnr,
            lnum = line_num, -- Already 0-indexed from Mago
            col = col,
            end_lnum = end_pos.line or line_num,
            end_col = -1, -- -1 means end of line
            severity = severity_map[severity_str] or vim.diagnostic.severity.INFO,
            message = message,
            source = 'mago',
            code = rule_code,
          }

          table.insert(diagnostics, diagnostic)
        end
      end
    end
  end

  return diagnostics
end

-- Lint a buffer
-- bufnr: buffer number (0 = current)
-- Returns: true on success, false on error
function M.lint_buffer(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  -- Only lint PHP files
  if vim.bo[bufnr].filetype ~= 'php' then
    return false
  end

  -- Get file path (must be saved)
  local filepath = vim.api.nvim_buf_get_name(bufnr)
  if filepath == '' or vim.fn.filereadable(filepath) ~= 1 then
    vim.notify('[mago.nvim] Buffer must be saved to disk before linting', vim.log.levels.WARN)
    return false
  end

  -- Get mago executable
  local executable = require 'mago.executable'
  local mago_path = executable.find()
  if not mago_path then
    vim.notify('[mago.nvim] Mago executable not found', vim.log.levels.ERROR)
    return false
  end

  -- Run mago lint
  local cmd = { mago_path, 'lint', '--reporting-format', 'json', filepath }
  local result = vim.system(cmd, { text = true }):wait()

  -- Parse diagnostics (success or failure)
  -- Mago may return exit code 1 if there are errors but still provide JSON
  if result.stdout and result.stdout ~= '' then
    local diagnostics = M.parse_diagnostics(result.stdout, bufnr)

    if diagnostics then
      -- Set diagnostics
      vim.diagnostic.set(ns, bufnr, diagnostics, {})

      -- Notify user
      local count = #diagnostics
      if count > 0 then
        vim.notify(string.format('[mago.nvim] Found %d issue(s)', count), vim.log.levels.INFO)
      else
        vim.notify('[mago.nvim] No issues found', vim.log.levels.INFO)
      end

      return true
    end
  end

  -- Handle errors
  if result.code ~= 0 and result.stderr and result.stderr ~= '' then
    vim.notify(string.format('[mago.nvim] Linting failed: %s', result.stderr), vim.log.levels.ERROR)
  end

  return false
end

-- Clear diagnostics for buffer
function M.clear_diagnostics(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  vim.diagnostic.reset(ns, bufnr)
end

-- Lint with auto-fix
function M.lint_fix(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  -- Only lint PHP files
  if vim.bo[bufnr].filetype ~= 'php' then
    return false
  end

  -- Get file path (must be saved)
  local filepath = vim.api.nvim_buf_get_name(bufnr)
  if filepath == '' or vim.fn.filereadable(filepath) ~= 1 then
    vim.notify('[mago.nvim] Buffer must be saved to disk before linting', vim.log.levels.WARN)
    return false
  end

  -- Get mago executable
  local executable = require 'mago.executable'
  local mago_path = executable.find()
  if not mago_path then
    vim.notify('[mago.nvim] Mago executable not found', vim.log.levels.ERROR)
    return false
  end

  -- Run mago lint --fix
  local cmd = { mago_path, 'lint', '--fix', '--reporting-format', 'json', filepath }
  local result = vim.system(cmd, { text = true }):wait()

  if result.code == 0 or (result.code == 1 and result.stdout) then
    -- Reload buffer to show fixes
    vim.api.nvim_buf_call(bufnr, function()
      vim.cmd 'checktime'
    end)

    -- Clear old diagnostics
    M.clear_diagnostics(bufnr)

    -- Notify user
    vim.notify('[mago.nvim] Applied auto-fixes, re-linting...', vim.log.levels.INFO)

    -- Re-lint after slight delay to ensure buffer reload
    vim.defer_fn(function()
      M.lint_buffer(bufnr)
    end, 100)

    return true
  else
    vim.notify(
      string.format('[mago.nvim] Auto-fix failed: %s', result.stderr or 'Unknown error'),
      vim.log.levels.ERROR
    )
    return false
  end
end

-- Lint with specific rules only
function M.lint_only(bufnr, rules)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  if not rules or #rules == 0 then
    vim.notify('[mago.nvim] No rules specified', vim.log.levels.WARN)
    return false
  end

  -- Only lint PHP files
  if vim.bo[bufnr].filetype ~= 'php' then
    return false
  end

  -- Get file path (must be saved)
  local filepath = vim.api.nvim_buf_get_name(bufnr)
  if filepath == '' or vim.fn.filereadable(filepath) ~= 1 then
    vim.notify('[mago.nvim] Buffer must be saved to disk before linting', vim.log.levels.WARN)
    return false
  end

  -- Get mago executable
  local executable = require 'mago.executable'
  local mago_path = executable.find()
  if not mago_path then
    vim.notify('[mago.nvim] Mago executable not found', vim.log.levels.ERROR)
    return false
  end

  -- Build command with --only flag
  local cmd = { mago_path, 'lint', '--reporting-format', 'json', '--only', table.concat(rules, ','), filepath }
  local result = vim.system(cmd, { text = true }):wait()

  -- Parse diagnostics
  if result.stdout and result.stdout ~= '' then
    local diagnostics = M.parse_diagnostics(result.stdout, bufnr)

    if diagnostics then
      -- Set diagnostics
      vim.diagnostic.set(ns, bufnr, diagnostics, {})

      -- Notify user
      local count = #diagnostics
      local rules_str = table.concat(rules, ', ')
      if count > 0 then
        vim.notify(
          string.format('[mago.nvim] Found %d issue(s) for rules: %s', count, rules_str),
          vim.log.levels.INFO
        )
      else
        vim.notify(string.format('[mago.nvim] No issues found for rules: %s', rules_str), vim.log.levels.INFO)
      end

      return true
    end
  end

  -- Handle errors
  if result.code ~= 0 and result.stderr and result.stderr ~= '' then
    vim.notify(string.format('[mago.nvim] Linting failed: %s', result.stderr), vim.log.levels.ERROR)
  end

  return false
end

return M
