local M = {}

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
        local actions = {}
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

M.setup = function()
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
