local function get_mago_executable() return require('mago.executable').get_or_error() end

local function save_cursor_position()
  local win = vim.api.nvim_get_current_win()
  local cursor_pos = vim.api.nvim_win_get_cursor(win)
  return { win = win, cursor_pos = cursor_pos }
end

local function restore_cursor_position(cursor_state, adjusted_pos)
  local pos = adjusted_pos or cursor_state.cursor_pos
  pcall(vim.api.nvim_win_set_cursor, cursor_state.win, pos)
end

local function handle_format_error(result, bufnr)
  local errors = require 'mago.errors'
  errors.handle(result.stderr, bufnr)
  return false
end

local function prepare_stdin_input(bufnr)
  local start_line = 0
  local end_line = -1
  local lines = vim.api.nvim_buf_get_lines(bufnr, start_line, end_line, false)
  local input = table.concat(lines, '\n')
  if #lines > 0 then input = input .. '\n' end
  return input
end

local function process_formatted_output(formatted)
  if formatted == nil then return nil end
  if formatted:sub(-1) == '\n' then formatted = formatted:sub(1, -2) end
  return vim.split(formatted, '\n', { plain = true })
end

local function apply_buffer_changes(bufnr, new_lines, cursor_state)
  local start_line = 0
  local end_line = -1
  vim.api.nvim_buf_set_lines(bufnr, start_line, end_line, false, new_lines)
  local new_line_count = #new_lines
  local adjusted_cursor = {
    math.min(cursor_state.cursor_pos[1], new_line_count),
    cursor_state.cursor_pos[2],
  }
  restore_cursor_position(cursor_state, adjusted_cursor)
end

local function format_with_stdin(bufnr)
  bufnr = bufnr or 0
  local mago_path = get_mago_executable()
  if not mago_path then return false end

  local input = prepare_stdin_input(bufnr)
  local cursor_state = save_cursor_position()

  local result = vim.system({ mago_path, 'fmt', '--stdin-input' }, { stdin = input, text = true }):wait()

  if result.code == 0 then
    local new_lines = process_formatted_output(result.stdout)
    if not new_lines then return false end
    apply_buffer_changes(bufnr, new_lines, cursor_state)
    return true
  else
    return handle_format_error(result, bufnr)
  end
end

local function format_with_filepath(bufnr, filepath)
  local mago_path = get_mago_executable()
  if not mago_path then return false end

  local cursor_state = save_cursor_position()

  local result = vim.system({ mago_path, 'fmt', filepath }, { text = true }):wait()

  if result.code == 0 then
    vim.api.nvim_buf_call(bufnr, function() vim.cmd 'edit!' end)
    restore_cursor_position(cursor_state)
    return true
  else
    return handle_format_error(result, bufnr)
  end
end

local M = {}

function M.format_buffer(bufnr)
  bufnr = bufnr or 0
  local filepath = vim.api.nvim_buf_get_name(bufnr)
  local is_modified = vim.bo[bufnr].modified

  if not is_modified and filepath then return format_with_filepath(bufnr, filepath) end

  return format_with_stdin(bufnr)
end

return M
