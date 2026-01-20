local M = {}
function M.show(lines)
  local width = vim.o.columns
  local height = vim.o.lines
  local win_width = math.floor(width * 0.8)
  local win_height = math.floor(height * 0.8)
  if win_width > 80 then
    win_width = 80
  end
  if win_height > #lines then
    win_height = #lines
  end
  local row = math.floor((height - win_height) / 2)
  local col = math.floor((width - win_width) / 2)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].readonly = true
  local opts = {
    relative = 'editor',
    width = win_width,
    height = win_height,
    row = row,
    col = col,
    style = 'minimal',
    border = 'rounded',
    focusable = true,
    noautocmd = true,
  }
  local win = vim.api.nvim_open_win(buf, true, opts)
  vim.wo[win].winblend = 0

  -- Close on q or Esc
  vim.api.nvim_buf_set_keymap(buf, 'n', 'q', ':close<CR>', { noremap = true, silent = true })
  vim.api.nvim_buf_set_keymap(buf, 'n', '<Esc>', ':close<CR>', { noremap = true, silent = true })

  -- Prevent leaving the window
  vim.api.nvim_create_autocmd('WinLeave', {
    buffer = buf,
    once = true,
    callback = function()
      vim.schedule(function()
        if vim.api.nvim_win_is_valid(win) then
          vim.api.nvim_set_current_win(win)
        end
      end)
    end,
  })
end
return M
