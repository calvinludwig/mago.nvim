local M = {}

-- Format buffer or range
-- bufnr: buffer number (0 = current buffer)
-- start_line: starting line (1-indexed, nil = first line)
-- end_line: ending line (1-indexed, nil = last line)
-- Returns: true on success, false on error
function M.format_buffer(bufnr, start_line, end_line)
  bufnr = bufnr or 0

  -- Get mago executable
  local executable = require 'mago.executable'
  local mago_path = executable.get_or_error()
  if not mago_path then
    return false
  end

  -- Get buffer lines
  start_line = start_line or 0
  end_line = end_line or -1

  local lines = vim.api.nvim_buf_get_lines(bufnr, start_line, end_line, false)
  local input = table.concat(lines, '\n')

  -- Add trailing newline if buffer is not empty
  if #lines > 0 then
    input = input .. '\n'
  end

  -- Save cursor position
  local win = vim.api.nvim_get_current_win()
  local cursor_pos = vim.api.nvim_win_get_cursor(win)

  -- Run mago format with stdin
  local result = vim.system({ mago_path, 'fmt', '--stdin-input' }, { stdin = input, text = true }):wait()

  -- Handle result
  if result.code == 0 then
    -- Successfully formatted
    local formatted = result.stdout

    -- Remove trailing newline if present to avoid extra blank line
    if formatted:sub(-1) == '\n' then
      formatted = formatted:sub(1, -2)
    end

    local new_lines = vim.split(formatted, '\n', { plain = true })

    -- Replace buffer content
    vim.api.nvim_buf_set_lines(bufnr, start_line, end_line, false, new_lines)

    -- Restore cursor position (adjust if necessary)
    local new_line_count = #new_lines
    local adjusted_cursor = {
      math.min(cursor_pos[1], new_line_count),
      cursor_pos[2],
    }
    pcall(vim.api.nvim_win_set_cursor, win, adjusted_cursor)

    vim.notify('[mago.nvim] Formatted successfully', vim.log.levels.INFO)
    return true
  else
    -- Formatting failed
    local errors = require 'mago.errors'
    errors.handle(result.stderr, bufnr)
    return false
  end
end

-- Format a specific range
-- Convenience wrapper for format_buffer with explicit range
function M.format_range(bufnr, start_line, end_line)
  if not start_line or not end_line then
    vim.notify('[mago.nvim] Invalid range specified', vim.log.levels.ERROR)
    return false
  end

  -- Convert to 0-indexed for nvim_buf_get_lines
  return M.format_buffer(bufnr, start_line - 1, end_line)
end

return M
