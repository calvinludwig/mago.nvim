local function create_server()
  local server = {}
  local linter = require 'mago.linter'
  local formatter = require 'mago.formatter'
  local closing = false

  function server.request(m, p, c)
    local methods = {
      ['initialize'] = function(_, callback)
        callback(nil, {
          capabilities = {
            codeActionProvider = true,
            textDocumentSync = 1,
            documentFormattingProvider = true,
          },
        })
      end,

      ['textDocument/formatting'] = function(params, callback)
        formatter.format_buffer(vim.uri_to_bufnr(params.textDocument.uri))
        callback(nil, {})
      end,

      ['textDocument/codeAction'] = function(params, callback)
        local bufnr = vim.uri_to_bufnr(params.textDocument.uri)
        local actions = {}
        
        -- Only provide actions for PHP files
        if vim.bo[bufnr].filetype ~= 'php' then
          callback(nil, actions)
          return
        end
        
        -- Get unique rules from current buffer
        local all_rules = linter.get_unique_rules(bufnr)
        
        if #all_rules == 0 then
          callback(nil, actions)
          return
        end
        
        -- Get rule at cursor position (params.range.start is 0-indexed)
        local cursor_line = params.range.start.line
        local cursor_col = params.range.start.character
        
        -- Check if there's a diagnostic on the current line (line-based, not column-based)
        local rule_on_line = linter.get_rule_at_position(bufnr, cursor_line, 0)
        
        -- If there's a diagnostic on current line, add "Explain" action FIRST
        if rule_on_line then
          table.insert(actions, {
            title = string.format('Explain [%s]', rule_on_line),
            kind = 'refactor.rewrite',
            command = {
              title = string.format('Explain %s', rule_on_line),
              command = 'mago.explain_rule',
              arguments = { rule_on_line },
            },
          })
        end
        
        -- Get rule at exact cursor position for ordering fix actions
        local rule_at_cursor = linter.get_rule_at_position(bufnr, cursor_line, cursor_col)
        
        -- Order rules: cursor rule first, then others in natural order
        local ordered_rules = {}
        if rule_at_cursor then table.insert(ordered_rules, rule_at_cursor) end
        
        for _, rule in ipairs(all_rules) do
          if rule ~= rule_at_cursor then table.insert(ordered_rules, rule) end
        end
        
        -- Create per-rule fix actions
        for _, rule_code in ipairs(ordered_rules) do
          table.insert(actions, {
            title = string.format('Fix [%s] in file', rule_code),
            kind = 'quickfix',
            command = {
              title = string.format('Fix %s', rule_code),
              command = 'mago.fix_rule',
              arguments = { bufnr, rule_code },
            },
          })
        end
        
        -- Add "Fix all" action at the bottom
        table.insert(actions, {
          title = 'Fix all Mago issues in file',
          kind = 'quickfix',
          command = {
            title = 'Fix all Mago issues',
            command = 'mago.fix_all',
            arguments = { bufnr },
          },
        })
        
        callback(nil, actions)
      end,

      ['shutdown'] = function(_, callback)
        closing = true
        callback(nil, nil)
      end,
    }

    local met = methods[m]

    if met then
      met(p, c)
      return
    end

    c(nil, nil)
  end

  function server.notify(m, p)
    local methods = {
      ['textDocument/didOpen'] = function(params)
        linter.lint(vim.uri_to_bufnr(params.textDocument.uri))
        --
      end,

      ['textDocument/didSave'] = function(params)
        linter.lint(vim.uri_to_bufnr(params.textDocument.uri))
        --
      end,

      ['textDocument/didChange'] = function(params)
        linter.clear_linting(vim.uri_to_bufnr(params.textDocument.uri))
        --
      end,

      ['textDocument/didClose'] = function(params)
        -- Handle document close
      end,
    }

    local met = methods[m]

    if met then met(p) end
  end

  function server.is_closing() return closing end

  function server.terminate()
    -- Cleanup
    closing = true
  end

  return server
end

local M = {}

M.setup = function()
  -- Register LSP command handlers for code actions
  vim.lsp.commands['mago.fix_all'] = function(command)
    local bufnr = command.arguments[1]
    require('mago.linter').fix_all(bufnr)
  end

  vim.lsp.commands['mago.fix_rule'] = function(command)
    local bufnr = command.arguments[1]
    local rule_code = command.arguments[2]
    require('mago.linter').fix_rule(bufnr, rule_code)
  end

  vim.lsp.commands['mago.explain_rule'] = function(command)
    local rule_code = command.arguments[1]
    require('mago.linter').show_rule_explanation(rule_code)
  end

  local client = vim.lsp.start {
    name = 'mago.nvim',
    cmd = create_server,
    root_dir = vim.fn.getcwd(),
  }

  if not client then
    vim.notify('[mago.nvim] Failed to start LSP client', vim.log.levels.ERROR)
    return
  end

  vim.api.nvim_create_autocmd('FileType', {
    pattern = 'php',
    callback = function() vim.lsp.buf_attach_client(0, client) end,
    desc = 'Attach mago.nvim LSP client to PHP buffers',
  })
end

return M
