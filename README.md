# mago.nvim

A Neovim plugin for [Mago](https://mago.carthage.software/), the blazing fast
PHP toolchain written in Rust.

## Features

- [x] Formatter (on save from LSP or :MagoFormat)
- [x] Linter (show diagnostics on file save)
- [x] Fix diagnostics with Code Actions
- [x] Explain Rule with Code Actions
- [ ] Analyzer

## Requirements

- Neovim >= 0.10.0
- [Mago](https://mago.carthage.software/) installed either:
  - In your project via Composer: `composer require --dev carthage/mago`
  - Globally in your `$PATH`

## Installation

### Using Neovim 0.12 vim.pack

```lua
vim.pack.add {
  { src = 'https://github.com/calvinludwig/mago.nvim' },
}

require('mago-nvim').setup()
```

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  'calvinludwig/mago.nvim',
  ft = 'php',  -- Load only for PHP files
  opts = {
    logging = {
      notify = true,
      write_to_log = false,
      min_level = 'INFO',
      log_file = nil,
    },
  },
}
```

### Configuration

```lua
require('mago-nvim').setup {
  logging = {
    notify = true, -- show vim.notify for stderr messages
    write_to_log = false, -- append filtered messages to a log file
    min_level = 'INFO', -- TRACE | DEBUG | INFO | WARN | ERROR
    log_file = nil, -- defaults to: vim.fn.stdpath('log') .. '/mago.nvim.log'
  },
}
```

## Usage

### Commands

- `:MagoFormat` - Format the current buffer
- `:MagoLintFix` - Fix all linting errors in the current buffer
- `:MagoExplainRule [rule]` - Show detailed explanation of a linter rule

## Troubleshooting

### Mago executable not found

- Install globally: Follow [Mago installation guide](https://mago.carthage.software/)
- Install via Composer: `composer require --dev carthage/mago`

## How It Works

mago.nvim implements a "fake" LSP server that runs in-process within Neovim,
rather than as a separate language server process. This design choice allows
for tight integration with Neovim's APIs.

The fake LSP server registers handlers for key LSP methods:

- `textDocument/formatting` - Formats the buffer using Mago
- `textDocument/codeAction` - Provides code actions for fixing and explaining rules
- `initialize` - Announces basic LSP capabilities

When you open a PHP file, mago.nvim automatically attaches this fake LSP
client, enabling all the standard LSP features like code actions and formatting
through Neovim's native LSP interface.

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## License

MIT License - see LICENSE file for details

## Related Projects

- [Mago](https://mago.carthage.software/) - The Oxidized PHP Toolchain
- [carthage/mago](https://github.com/carthage-software/mago) - Mago on GitHub
