local M = {}

-- Parse a single error line
-- Expected format variations:
--   file.php:15:3: error message
--   Error: error message
-- Returns: { filename, lnum, col, text } or nil
function M.parse_error(error_line)
  if not error_line or error_line == '' then
    return nil
  end

  -- Try to parse file:line:col: message format
  local filename, lnum, col, text = error_line:match '^(.-)%:(%d+)%:(%d+)%:%s*(.*)$'
  if filename and lnum and col and text then
    return {
      filename = filename,
      lnum = tonumber(lnum),
      col = tonumber(col),
      text = text,
    }
  end

  -- Try to parse file:line: message format (no column)
  filename, lnum, text = error_line:match '^(.-)%:(%d+)%:%s*(.*)$'
  if filename and lnum and text then
    return {
      filename = filename,
      lnum = tonumber(lnum),
      col = 1,
      text = text,
    }
  end

  -- Generic error without location info
  return {
    filename = '',
    lnum = 1,
    col = 1,
    text = error_line,
  }
end

-- Handle errors from mago
-- Displays notification and populates quickfix list
function M.handle(stderr, bufnr)
  local config = require('mago.config').get()

  if not stderr or stderr == '' then
    stderr = 'Unknown error occurred'
  end

  -- Show notification
  if config.notify_on_error then
    local lines = vim.split(stderr, '\n', { plain = true })
    local first_line = lines[1] or 'Formatting failed'

    vim.notify(string.format('[mago.nvim] %s', first_line), vim.log.levels.ERROR)
  end

  -- Populate quickfix list
  if config.quickfix_on_error then
    local qf_entries = {}
    local lines = vim.split(stderr, '\n', { plain = true })

    for _, line in ipairs(lines) do
      local entry = M.parse_error(line)
      if entry and entry.text ~= '' then
        -- If no filename, use current buffer
        if entry.filename == '' and bufnr then
          entry.bufnr = bufnr
        end
        table.insert(qf_entries, entry)
      end
    end

    if #qf_entries > 0 then
      vim.fn.setqflist(qf_entries, 'r')
      vim.notify(
        string.format('[mago.nvim] %d error(s) added to quickfix list. Use :copen to view.', #qf_entries),
        vim.log.levels.INFO
      )
    end
  end
end

return M
