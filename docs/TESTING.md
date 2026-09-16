# Validation and test scope

## Offline checks

Python 3.11 or newer:

```powershell
python tests/test_config.py
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\test-scripts.ps1
```

PowerShell 7 can also run `./tests/test-scripts.ps1`. Run PowerShell tests in a fresh
terminal process: they temporarily change process environment variables, create an
isolated temporary directory, mock `codex` and clean up afterward. They do not use
real API keys, run models or modify your actual user config.

Checks cover TOML/JSON parsing, root/reviewer settings, image metadata, local
Markdown links, obvious credential patterns, PowerShell syntax, installer config
preservation/backups, role sandboxes, stdin/Unicode forwarding, image arguments,
missing-key errors and nonzero subprocess results.

These are package-level and mocked launcher tests, NOT proof of current model
availability, actual image interpretation, provider compatibility, sandbox enforcement,
MCP isolation, or end-to-end orchestration. They do not cover every native npm/CLI
argument-handling combination. The credential-pattern check is not a comprehensive
secret audit. See this repository's Actions tab for actual CI status.

## Live acceptance checks (user-controlled API usage)

1. From the intended Git working tree, run the researcher greeting and verify
   Flash selection. This is a real API call and may incur charges.
2. Attach a non-sensitive screenshot and verify the answer references its actual
   contents, rather than relying on a model's own claim of vision support.
3. Run a bounded worker in a disposable branch/worktree, inspect the diff and run
   the project's own tests.
4. Confirm the parent remains Astra medium and `final_reviewer` uses Astra high
   when requested, subject to account and permission restrictions.

Never describe skipped, mocked or syntax-only tests as live integration passes.
