local function create_server(dispatchers)
  local diagnostics = require 'mago-nvim.server.diagnostics'
  local code_actions = require 'mago-nvim.server.code-actions'

  local server = {}
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
        require('mago-nvim.server.format').format_uri(params.textDocument.uri)
        callback(nil, {})
      end,

      ['textDocument/codeAction'] = function(params, callback)
        local bufnr = vim.uri_to_bufnr(params.textDocument.uri)

        local actions = code_actions.retrieve_from_buffer(bufnr)
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
        diagnostics.publish(params.textDocument.uri, dispatchers)
        --
      end,

      ['textDocument/didSave'] = function(params)
        diagnostics.publish(params.textDocument.uri, dispatchers)
        --
      end,

      ['textDocument/didChange'] = function(_)
        --
      end,

      ['textDocument/didClose'] = function(_)
        --
      end,
    }

    local met = methods[m]

    if met then
      met(p)
    end
  end

  function server.is_closing()
    return closing
  end

  function server.terminate()
    closing = true
  end

  return server
end

local function start_mago(bufnr)
  vim.schedule(function()
    vim.lsp.start({
      name = 'mago.nvim',
      cmd = create_server,
      root_dir = vim.fn.getcwd(),
    }, {
      bufnr = bufnr,
    })
  end)
end

local M = {}

M.setup = function()
  if vim.bo.filetype == 'php' then
    start_mago(0)
  end

  vim.api.nvim_create_autocmd('FileType', {
    pattern = 'php',
    callback = function(args)
      start_mago(args.buf)
      --
    end,
    desc = 'Start/attach mago.nvim LSP for PHP',
  })

  vim.lsp.commands['mago.explain_rule'] = function(command)
    local rule = command.arguments[1]
    require('mago-nvim.server.rules').popup_explain(rule)
  end

  vim.lsp.commands['mago.fix_all'] = function(command)
    local bufnr = command.arguments[1]
    require('mago-nvim.server.fixer').fix(bufnr)
  end

  vim.lsp.commands['mago.fix_rule'] = function(command)
    local bufnr = command.arguments[1]
    local rule = command.arguments[2]
    require('mago-nvim.server.fixer').fix(bufnr, rule)
  end
end

return M
