# mago.nvim

A Neovim plugin for [Mago](https://mago.carthage.software/), the blazing fast PHP toolchain written in Rust.

## Features

- **Format PHP files** with Mago's opinionated formatter
- **Lint PHP files** with Mago's powerful linter
- **Native diagnostics** using Neovim's built-in diagnostic system
- **Auto-fix** lint issues automatically
- **Rule management** - list, explain, and filter linting rules
- **Format/Lint on save** (optional)
- **Format visual selections** or ranges
- **Auto-detection** of Mago executable (project or global)

## Requirements

- Neovim >= 0.10.0
- [Mago](https://mago.carthage.software/) installed either:
  - Globally in your `$PATH`
  - In your project via Composer: `composer require --dev carthage/mago`

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  'calvinludwig/mago.nvim',
  ft = 'php',  -- Load only for PHP files
  opts = {
    format_on_save = false,  -- Enable auto-format on save
  },
}
```

## Configuration

Default configuration:

```lua
require('mago').setup({
  -- Formatter
  format_on_save = false,     -- Auto-format on save

  -- Linter
  lint_on_save = false,       -- Auto-lint on save
  lint_severity = 'hint',     -- Minimum severity: error/warning/info/hint

  -- Shared
  mago_path = nil,            -- Custom mago path (nil = auto-detect)
  notify_on_error = true,     -- Show vim.notify on error
  quickfix_on_error = true,   -- Populate quickfix on error
})
```

### Options

#### Formatter

- `format_on_save` (boolean): Automatically format PHP files when saving

#### Linter

- `lint_on_save` (boolean): Automatically lint PHP files when saving
- `lint_severity` (string): Minimum severity level to show diagnostics
  - `"error"` - Show only errors
  - `"warning"` - Show warnings and errors
  - `"info"` - Show info, warnings, and errors
  - `"hint"` - Show all diagnostics (default)

#### Shared

- `mago_path` (string|nil): Custom path to Mago executable. If `nil`, auto-detects from `vendor/bin/mago` or global `mago`
- `notify_on_error` (boolean): Show notification when operations fail
- `quickfix_on_error` (boolean): Populate quickfix list with errors (formatter only)

## Usage

### Commands

#### Formatting

- `:MagoFormat` - Format the current buffer
- `:MagoFormatRange` - Format a visual selection or range
- `:MagoToggleFormatOnSave` - Toggle format on save

#### Linting

- `:MagoLint` - Lint the current buffer
- `:MagoLintFix` - Lint with auto-fix enabled
- `:MagoLintOnly <rules>` - Lint with specific rules only (comma-separated)
- `:MagoClearDiagnostics` - Clear linting diagnostics for current buffer
- `:MagoToggleLintOnSave` - Toggle lint on save

#### Rule Management

- `:MagoListRules` - Display all available linting rules
- `:MagoExplainRule <rule>` - Show detailed explanation of a specific rule

#### Information

- `:MagoInfo` - Show Mago executable path, version, and status

### Keymaps

Add to your `init.lua`:

```lua
-- Formatting
vim.keymap.set('n', '<leader>mf', '<cmd>MagoFormat<cr>', { desc = 'Mago format' })
vim.keymap.set('v', '<leader>mf', '<cmd>MagoFormatRange<cr>', { desc = 'Mago format range' })

-- Linting
vim.keymap.set('n', '<leader>ml', '<cmd>MagoLint<cr>', { desc = 'Mago lint' })
vim.keymap.set('n', '<leader>mF', '<cmd>MagoLintFix<cr>', { desc = 'Mago lint fix' })

-- Rule management
vim.keymap.set('n', '<leader>mr', '<cmd>MagoListRules<cr>', { desc = 'Mago list rules' })

-- Information
vim.keymap.set('n', '<leader>mi', '<cmd>MagoInfo<cr>', { desc = 'Mago info' })
```

### Auto-format and Auto-lint on Save

Enable in your setup:

```lua
require('mago').setup({
  format_on_save = true,
  lint_on_save = true,
})
```

Or toggle dynamically:

```vim
:MagoToggleFormatOnSave
:MagoToggleLintOnSave
```

### Visual Range Formatting

1. Select lines in visual mode (`V`)
2. Run `:MagoFormatRange` or use your keymap

### Linting

The linter uses Neovim's built-in diagnostic system to display issues with:
- **Virtual text** - Inline error messages
- **Signs** - Icons in the gutter
- **Underlines** - Highlighting problematic code

#### Lint Current Buffer

```vim
:MagoLint
```

#### Auto-fix Issues

```vim
:MagoLintFix
```

This will automatically fix issues that Mago can resolve, reload the buffer, and re-lint to show remaining issues.

#### Lint with Specific Rules

```vim
:MagoLintOnly rule1,rule2,rule3
```

#### View and Explain Rules

```vim
:MagoListRules                    " List all available rules
:MagoExplainRule <rule_code>      " Show detailed explanation
```

#### Severity Filtering

Configure the minimum severity level to display:

```lua
require('mago').setup({
  lint_severity = 'warning',  -- Only show warnings and errors
})
```

## Integration with Other Plugins

### conform.nvim

```lua
require('conform').setup({
  formatters_by_ft = {
    php = { 'mago' },
  },
  formatters = {
    mago = {
      command = function()
        return require('mago.executable').find() or 'mago'
      end,
      args = { 'fmt', '--stdin-input' },
      stdin = true,
    },
  },
})
```

## How It Works

1. **Executable Detection**: The plugin searches for Mago in this order:
   - Custom `mago_path` from config
   - `vendor/bin/mago` in your project (searches upward from current file)
   - Global `mago` in `$PATH`

2. **Formatting**: Runs `mago fmt --stdin-input`, passing your buffer content via stdin

## Troubleshooting

### Mago executable not found

Run `:MagoInfo` to check if Mago is detected. If not:

- Install globally: Follow [Mago installation guide](https://mago.carthage.software/)
- Install via Composer: `composer require --dev carthage/mago`
- Set custom path:

  ```lua
  require('mago').setup({
    mago_path = '/path/to/mago',
  })
  ```

### Formatting errors

- Check the quickfix list: `:copen`
- Ensure your PHP file has valid syntax
- Check Mago's configuration (`mago.toml` in your project root)

## Roadmap

Future features planned:

- Async formatting and linting
- Static analyzer integration
- Architectural guard integration

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## License

MIT License - see LICENSE file for details

## Related Projects

- [Mago](https://mago.carthage.software/) - The Oxidized PHP Toolchain
- [carthage/mago](https://github.com/carthage/mago) - Mago on GitHub
