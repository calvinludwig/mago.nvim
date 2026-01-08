# mago.nvim

A Neovim plugin for [Mago](https://mago.carthage.software/), the blazing fast PHP toolchain written in Rust.

## Features

- **Format PHP files** with Mago's opinionated formatter
- **Lint PHP files** with Mago's powerful linter
- **Native diagnostics** using Neovim's built-in diagnostic system
- **LSP Code Actions** - Apply fixes via native `vim.lsp.buf.code_action()`
- **Format/Lint on save** (optional)
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
  format_on_save = true,          -- Auto-format on save
  lint_on_save = true,            -- Auto-lint on save
})
```

### Options

#### Formatter

- `format_on_save` (boolean): Automatically format PHP files when saving

#### Linter

- `lint_on_save` (boolean): Automatically lint PHP files when saving

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
- `:MagoCodeAction` - Show Mago code actions at cursor (filters to Mago fixes only)

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

-- Code Actions
vim.keymap.set('n', '<leader>ma', vim.lsp.buf.code_action, { desc = 'Code action' })

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

### Code Actions

Mago.nvim integrates with Neovim's native LSP code action system, allowing you to apply fixes through the standard `vim.lsp.buf.code_action()` interface.

#### Triggering Code Actions

Position your cursor on a line with a diagnostic and run:

```vim
:lua vim.lsp.buf.code_action()
```

Or use your configured keybinding (e.g., `<leader>ca` or `<leader>ma`).

#### Available Actions

When triggered on a PHP file with mago diagnostics, you'll see:

1. **Fix [RULE_CODE]: description** - Fix the specific diagnostic at cursor position
   - Runs `mago lint --fix --only {rule_code}` for targeted fixes
   - Only appears for diagnostics with rule codes

2. **Fix all issues at cursor (N rules)** - Fix all diagnostics at cursor position
   - Runs `mago lint --fix --only rule1,rule2,rule3`
   - Only appears when cursor has multiple different rule violations
   - Uses mago's comma-separated --only syntax

3. **Fix all errors/warnings/info/hints (N issues, M rules)** - Fix by severity level
   - Runs `mago lint --fix --only rule1,rule2,...` for all rules at that severity
   - Groups diagnostics by severity (Error, Warning, Info, Hint)
   - Useful for addressing high-priority issues first

4. **Fix all issues with Mago (N issues)** - Fix all linting issues in the file
   - Runs `mago lint --fix` on the entire file
   - Always available when diagnostics exist

**Example code action menu:**

```
Available code actions:
  1. Fix [no-unused-variable]: Remove unused variable $foo
  2. Fix [no-empty]: Remove empty block
  3. Fix all issues at cursor (2 rules)
  4. Fix all errors (5 issues, 3 rules)
  5. Fix all warnings (2 issues, 1 rule)
  6. Fix all issues with Mago (7 issues)
```

#### Integration with Code Action UIs

Mago code actions work seamlessly with:

- Native `vim.ui.select`
- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) with `telescope-ui-select`
- [fzf-lua](https://github.com/ibhagwan/fzf-lua)
- [dressing.nvim](https://github.com/stevearc/dressing.nvim)
- Any other code action UI plugin

#### Filter to Mago Actions Only

Use the `:MagoCodeAction` command to show only Mago fixes:

```vim
:MagoCodeAction
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
   - `vendor/bin/mago` in your project (searches upward from current file)
   - Global `mago` in `$PATH`

2. **Formatting**: Runs `mago fmt --stdin-input`, passing your buffer content via stdin

## Troubleshooting

### Mago executable not found

Run `:MagoInfo` to check if Mago is detected. If not:

- Install globally: Follow [Mago installation guide](https://mago.carthage.software/)
- Install via Composer: `composer require --dev carthage/mago`

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
