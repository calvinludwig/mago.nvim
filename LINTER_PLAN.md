Mago Linter Integration Implementation Plan

 Overview

 Add comprehensive linter integration to mago.nvim using native Neovim diagnostics, following existing plugin
 architecture patterns.

 Key Technical Decisions

 1. Output Format: JSON

- Use --reporting-format json for structured data
- Provides severity levels, rule codes, precise locations
- Command: mago lint --reporting-format json <file_path>

 1. Diagnostic Namespace

- Single namespace: vim.api.nvim_create_namespace('mago_linter')
- Isolates Mago diagnostics from LSP and other sources

 1. Input Method: File Path

- Pass file path directly (not stdin like formatter)
- Linter needs project context for imports/dependencies
- Requires file to be saved to disk
- Lint on BufWritePost (after save)

 1. Severity Mapping

 {
   error = vim.diagnostic.severity.ERROR,
   warning = vim.diagnostic.severity.WARN,
   info = vim.diagnostic.severity.INFO,
   hint = vim.diagnostic.severity.HINT,
 }

 1. Rule Code Display

- Format: [RULE_CODE] message
- Example: [E001] Undefined variable $foo

 1. Auto-fix Behavior

- Clear diagnostics → Run mago lint --fix → Reload buffer → Re-lint

 ---
 File Structure

 New Files

 lua/mago/linter.lua (Core linting)

 Exports:

- get_namespace() - Returns diagnostic namespace
- parse_diagnostics(json_output, bufnr) - Parse JSON to vim.diagnostic format
- lint_buffer(bufnr) - Main linting function
- lint_fix(bufnr) - Lint with auto-fix
- clear_diagnostics(bufnr) - Clear buffer diagnostics
- lint_only(bufnr, rules) - Lint with specific rules

 Key Logic:

 1. Validate buffer (PHP filetype, saved to disk)
 2. Get Mago executable
 3. Run mago lint --reporting-format json <filepath>
 4. Parse JSON output
 5. Filter by configured severity
 6. Transform to vim.diagnostic format
 7. Set diagnostics with vim.diagnostic.set(ns, bufnr, diagnostics)

 lua/mago/rules.lua (Rule management)

 Exports:

- fetch_rules() - Fetch rules with --list-rules --json (cached)
- list_rules() - Display rules in split buffer
- explain_rule(rule_code) - Show rule explanation in split buffer

 Modified Files

 lua/mago/config.lua

 Add to defaults:
 lint_on_save = false,      -- Auto-lint on save
 lint_severity = 'hint',    -- Minimum severity: error/warning/info/hint

 lua/mago/commands.lua

 Add commands:

- :MagoLint - Lint current buffer
- :MagoLintFix - Lint with auto-fix
- :MagoListRules - List available rules
- :MagoExplainRule <rule> - Explain specific rule
- :MagoLintOnly <rules> - Lint with specific rules (comma-separated)
- :MagoClearDiagnostics - Clear diagnostics
- :MagoToggleLintOnSave - Toggle lint on save

 Update :MagoInfo:

- Add linter status (lint_on_save, lint_severity)
- Show diagnostic count for current buffer

 lua/mago/init.lua

 Add functions:

- setup_lint_on_save() - Create BufWritePost autocmd
- toggle_lint_on_save() - Toggle lint on save

 Update setup():
 if config.get().lint_on_save then
   M.setup_lint_on_save()
 end

 ---
 Implementation Details

 Diagnostic Format

 {
   bufnr = bufnr,
   lnum = line - 1,          -- 0-indexed
   col = col - 1,            -- 0-indexed
   end_lnum = end_line - 1,
   end_col = end_col - 1,
   severity = vim.diagnostic.severity.ERROR,
   message = "[E001] Undefined variable $foo",
   source = "mago",
   code = "E001",
 }

 Severity Filtering

 -- In parse_diagnostics()
 local function meets_severity_threshold(diagnostic_severity, min_severity)
   local levels = { error = 1, warning = 2, info = 3, hint = 4 }
   return levels[diagnostic_severity] <= levels[min_severity]
 end

 -- Filter diagnostics
 for _, diag in ipairs(json_diagnostics) do
   if meets_severity_threshold(diag.level, config.lint_severity) then
     table.insert(diagnostics, parsed_diagnostic)
   end
 end

 Lint on Save Setup

 function M.setup_lint_on_save()
   local group = vim.api.nvim_create_augroup('MagoLint', { clear = true })

   vim.api.nvim_create_autocmd('BufWritePost', {
     pattern = '*.php',
     group = group,
     callback = function(ev)
       require('mago.linter').lint_buffer(ev.buf)
     end,
     desc = 'Lint PHP file with Mago after saving',
   })
 end

 Auto-fix with Buffer Reload

 function M.lint_fix(bufnr)
   -- Run mago lint --fix
   local result = vim.system(
     { mago_path, 'lint', '--fix', '--reporting-format', 'json', filepath },
     { text = true }
   ):wait()

   -- Reload buffer
   vim.api.nvim_buf_call(bufnr, function()
     vim.cmd('checktime')
   end)

   -- Clear old diagnostics
   M.clear_diagnostics(bufnr)

   -- Re-lint after slight delay
   vim.defer_fn(function()
     M.lint_buffer(bufnr)
   end, 100)
 end

 ---
 Error Handling

 Buffer not saved:
 local filepath = vim.api.nvim_buf_get_name(bufnr)
 if filepath == '' or vim.fn.filereadable(filepath) ~= 1 then
   vim.notify('[mago.nvim] Buffer must be saved to disk before linting',
              vim.log.levels.WARN)
   return false
 end

 Non-PHP buffer: Silent return (no notification)

 Mago not found: Show error notification

 JSON parse failure: Graceful error with notification

 Exit codes:

- Code 0: Success
- Code 1 with stdout: Issues found (not an error)
- Other: Actual error, show stderr

 ---
 Implementation Order

 Phase 1: Core Linting (Priority 1)

 1. Create lua/mago/linter.lua

- get_namespace(), parse_diagnostics(), lint_buffer(), clear_diagnostics()

 1. Extend lua/mago/config.lua

- Add lint_on_save, lint_severity

 1. Add commands to lua/mago/commands.lua

- :MagoLint, :MagoClearDiagnostics

 Phase 2: Lint on Save (Priority 2)

 1. Extend lua/mago/init.lua

- setup_lint_on_save(), toggle_lint_on_save(), update setup()

 1. Add command

- :MagoToggleLintOnSave

 Phase 3: Auto-fix (Priority 3)

 1. Extend lua/mago/linter.lua

- lint_fix() with reload logic

 1. Add command

- :MagoLintFix

 Phase 4: Rule Management (Priority 4)

 1. Create lua/mago/rules.lua

- fetch_rules(), list_rules(), explain_rule()

 1. Add commands

- :MagoListRules, :MagoExplainRule

 Phase 5: Advanced Linting (Priority 5)

 1. Extend lua/mago/linter.lua

- lint_only(bufnr, rules)

 1. Add command

- :MagoLintOnly

 Phase 6: Documentation (Priority 6)

 1. Update README.md

- Add linter features, commands, configuration, keymaps

 1. Update :MagoInfo command

- Add linter status and diagnostic count

 ---
 Critical Files

 1. lua/mago/linter.lua (NEW) - Core linting, diagnostic parsing
 2. lua/mago/rules.lua (NEW) - Rule management
 3. lua/mago/config.lua (MODIFY) - Add config options
 4. lua/mago/commands.lua (MODIFY) - Add 7 commands
 5. lua/mago/init.lua (MODIFY) - Add lint-on-save setup
 6. README.md (MODIFY) - Documentation updates

 ---
 Key APIs Used

- vim.diagnostic.set(namespace, bufnr, diagnostics) - Set diagnostics
- vim.diagnostic.reset(namespace, bufnr) - Clear diagnostics
- vim.diagnostic.get(bufnr, { namespace = ns }) - Get diagnostics
- vim.api.nvim_create_namespace('mago_linter') - Create namespace
- vim.system(cmd, opts):wait() - Execute mago commands
- vim.json.decode(json_string) - Parse JSON output
- vim.api.nvim_create_autocmd('BufWritePost', ...) - Lint on save
- vim.api.nvim_create_augroup('MagoLint', ...) - Manage autocmds

 ---
 Configuration Example

 require('mago').setup({
   -- Formatter
   format_on_save = false,

   -- Linter
   lint_on_save = true,           -- Enable lint on save
   lint_severity = 'warning',     -- Show warnings and errors only

   -- Shared
   mago_path = nil,               -- Auto-detect
   notify_on_error = true,
   quickfix_on_error = true,
 })

 Commands Summary

 | Command                 | Description              |
 |-------------------------|--------------------------|
 | :MagoLint               | Lint current buffer      |
 | :MagoLintFix            | Lint with auto-fix       |
 | :MagoListRules          | List available rules     |
 | :MagoExplainRule <rule> | Explain specific rule    |
 | :MagoLintOnly <rules>   | Lint with specific rules |
 | :MagoClearDiagnostics   | Clear diagnostics        |
 | :MagoToggleLintOnSave   | Toggle lint on save      |
 | :MagoInfo               | Show status (updated)    |

 Suggested Keymaps

 vim.keymap.set('n', '<leader>ml', '<cmd>MagoLint<cr>', { desc = 'Mago lint' })
 vim.keymap.set('n', '<leader>mF', '<cmd>MagoLintFix<cr>', { desc = 'Mago lint fix' })
 vim.keymap.set('n', '<leader>mr', '<cmd>MagoListRules<cr>', { desc = 'Mago list rules' })
