# mago.nvim

> **🚧 UNDER CONSTRUCTION - NOT READY FOR USE 🚧**
>
> This plugin is currently under active development and is not yet ready for
> production use.

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

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  'calvinludwig/mago.nvim',
  ft = 'php',  -- Load only for PHP files
  opts = {},
}
```

## Usage

### Commands

- `:MagoFormat` - Format the current buffer
- `:MagoFixAll` - Fix all linting errors in the current buffer
- `:MagoExplainRule [rule]` - Show detailed explanation of a linter rule (uses cursor diagnostic if no rule specified)
- `:MagoInfo` - Show Mago executable path, version, and plugin status

## How It Works

TODO: exaplain the fake LSP

## Troubleshooting

### Mago executable not found

Run `:MagoInfo` to check if Mago is detected. If not:

- Install globally: Follow [Mago installation guide](https://mago.carthage.software/)
- Install via Composer: `composer require --dev carthage/mago`

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## License

MIT License - see LICENSE file for details

## Related Projects

- [Mago](https://mago.carthage.software/) - The Oxidized PHP Toolchain
- [carthage/mago](https://github.com/carthage/mago) - Mago on GitHub
