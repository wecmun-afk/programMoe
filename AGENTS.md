# Multi-Agent Orchestration

You are the root/orchestrator.

Use GPT-6 Astra at medium reasoning for planning, decomposition, integration,
verification and final implementation decisions.

Delegate bounded work when delegation is worthwhile.

## Research

For repository exploration, dependency investigation, documentation research,
or focused analysis, run:

```powershell
powershell -ExecutionPolicy Bypass -File "$HOME\.codex\bin\deepseek-agent.ps1" -Role researcher -Task "<task>"
```

## Implementation

For isolated implementation, refactoring, test writing, debugging or repetitive coding, run:

```powershell
powershell -ExecutionPolicy Bypass -File "$HOME\.codex\bin\deepseek-agent.ps1" -Role worker -Task "<task>"
```

## Writing

For documentation, summaries, changelogs, comments and technical prose, run:

```powershell
powershell -ExecutionPolicy Bypass -File "$HOME\.codex\bin\deepseek-agent.ps1" -Role writer -Task "<task>"
```

## Integration

After delegated tasks finish:

1. Inspect their outputs.
2. Verify relevant files yourself.
3. Integrate only compatible results.
4. Run relevant tests.
5. Resolve conflicts yourself.

Do not delegate tiny tasks where delegation costs more than doing the task directly.

Use the high-reasoning reviewer only for architecture changes, security-sensitive
changes, major database migrations, difficult concurrency issues, large cross-module
refactors, or failed verification where the cause remains unclear.
