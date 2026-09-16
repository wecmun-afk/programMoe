# Detailed installation — Codex + Astra + DeepSeek Flash

[ภาษาไทย / quick start](../README.md)

The parent uses **GPT-6 Astra medium** for planning, integration and verification.
Separate `codex exec` processes use **DeepSeek Flash** for bounded tasks. An optional
**Astra high** reviewer handles high-risk work. This is a workflow template, not
a guaranteed cost-saving scheduler.

## 1. Prerequisites and installation

Use Windows, PowerShell 5.1+ (or PowerShell 7), Git, Node.js/npm and a current Codex
CLI. Your account must actually have access to `gpt-6-astra`. VS Code and its Codex
extension are optional. DeepSeek needs its own API key; API usage and the parent's
account entitlement are separate.

```powershell
git clone https://github.com/wecmun-afk/programMoe.git
cd programMoe
npm install -g @openai/codex@latest
codex --version
codex login
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\install.ps1
```

Review scripts before executing. The process-level execution-policy flag does not
change permanent machine policy or override organization requirements. Installation
copies files only: it never signs in, installs the CLI or calls models.

The destination is `$env:CODEX_HOME`, or `$HOME\.codex` if unset:

```text
.codex/
  config.toml                       # Created only when absent
  config.programmoe.example.toml     # For deliberate merging
  bin/deepseek-agent.ps1
  agents/final-reviewer.toml
  programmoe/deepseek-models.json
```

Changed package files are backed up before replacement. Existing user config,
credentials and project `AGENTS.md` remain untouched. `-CodexHome` changes only the
installer destination; set `CODEX_HOME` to the same directory for later calls.

## 2. Configure the Astra parent

For a fresh setup the installer creates the example config. For an existing setup,
merge [config.example.toml](../.codex/config.example.toml) into your user config.
Keep root keys before the first TOML table. Update existing keys/tables instead of
duplicating them; preserve MCP, trust and administrator settings.

```toml
model = "gpt-6-astra"
model_provider = "openai"
model_reasoning_effort = "medium"
approval_policy = "on-request"
sandbox_mode = "workspace-write"

[features]
multi_agent = true

[agents]
enabled = true
max_concurrent_threads_per_session = 4
```

Current Codex discovers the custom reviewer from `agents/final-reviewer.toml`.
That file includes `name`, `description` and `developer_instructions` plus its model
and sandbox defaults. Update the CLI if your version does not support these fields.
Do not assume a minimum release solely from a screenshot.

The launcher supplies its own DeepSeek provider overrides. Do NOT replace the
parent's provider, force global API-only login, or set a DeepSeek-only catalog for
the parent. The included small worker catalog has project-authored instructions;
it is not a copy of vendor system prompts.

## 3. Set the DeepSeek key locally

```powershell
$secret = Read-Host 'DeepSeek API key' -AsSecureString
$credential = New-Object System.Management.Automation.PSCredential('deepseek', $secret)
$env:DEEPSEEK_API_KEY = $credential.GetNetworkCredential().Password
[Environment]::SetEnvironmentVariable('DEEPSEEK_API_KEY', $env:DEEPSEEK_API_KEY, 'User')
Remove-Variable secret, credential
```

Omit `SetEnvironmentVariable` to keep the key in this session only. A persistent
user environment variable is NOT an encrypted secrets vault. Restart the IDE and
terminal after changing persistent variables. Never commit a key, `.env`, login
files, transcripts or environment dumps. Keys are not printed or passed in command
arguments by the launcher.

## 4. Apply to the target repository

Merge [AGENTS.md](../AGENTS.md) into the target project's root, preserving existing
project instructions. Open PowerShell in that project's Git working tree, not the
setup repository. A downloaded ZIP is not a Git working tree: clone the project's
existing repository, or initialize a new repository only when appropriate.

```powershell
$ch = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $HOME '.codex' }
$launcher = Join-Path $ch 'bin/deepseek-agent.ps1'
& $launcher -Role researcher -Task 'Describe the relevant modules.' -DryRun
& $launcher -Role researcher -Task 'Reply only with: DeepSeek worker OK'
codex -m gpt-6-astra -c 'model_reasoning_effort="medium"'
```

The first call is offline. The second calls the API and may incur charges. Check
that the root session actually uses Astra: launch-time overrides can supersede
configuration. Respect managed policies and outer sandbox restrictions.

If unsigned scripts are blocked, use a reviewed script in a separate process instead
of changing permanent execution policy:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File $launcher `
  -Role researcher -Task 'Summarize the relevant code without editing.'
```

## 5. Worker options and images

| Option | Meaning |
|---|---|
| `-Role researcher` | Inspect supplied/repository evidence; read-only |
| `-Role worker` | Bounded implementation; workspace-write |
| `-Role writer` | Return a documentation draft; read-only |
| `-Task` | Inline task text |
| `-TaskFile` | UTF-8 task file instead of `-Task` |
| `-ProjectPath` | Target directory; current directory by default |
| `-ImagePath` | One or more local image paths |
| `-ReasoningEffort` | `low` (default), `high`, or `max` |
| `-DryRun` | Print invocation metadata without calling CLI/API |

Relative task/image paths resolve against `ProjectPath`. Tasks go over stdin and
are never evaluated as shell code. String configuration overrides use Codex's
literal-string fallback to avoid embedded-quote issues in Windows PowerShell 5.1.

```powershell
& $launcher -Role worker -ProjectPath 'C:\projects\my-app' `
  -TaskFile '.\tasks\fix-login.txt' -ReasoningEffort high

& $launcher -Role researcher -Task 'Explain the screenshot. Do not edit.' `
  -ImagePath '.\screenshots\error.png'

& $launcher -Role writer -Task 'Draft release notes for the verified changes.'
```

The launcher uses `deepseek-flash`, the Responses protocol, image-capable metadata
and disabled built-in web search. Catalog selection applies only to the worker.
Explicitly attach images: parent image context is not automatically transferred.
See current [Vision limits](https://api-docs.deepseek.com/guides/vision).

Workers disable native subagents and are instructed not to invoke children. Their
non-interactive `approval_policy=never` does NOT grant unrestricted access: escalation
cannot be approved and the role's sandbox remains. If an outer sandbox blocks the
API connection, obtain permission instead of disabling isolation. Read-only does
not remove network access, external tools or all sensitive files from visibility.

## 6. Integration and optional high review

Ask Astra to follow `AGENTS.md` for a specific feature. It should inspect actual
diffs and run relevant tests. The writer returns a draft for the root to apply.
Use `final_reviewer` for risky architecture/security/data-integrity work, not every
small edit. Live parent permission overrides can be inherited by native subagents;
the reviewer's read-only setting is a default, not an absolute guarantee.

Use sequential workers first, or separate Git worktrees for parallel implementation.
Native subagent limits do not count launcher processes. This package provides no
automatic spending cap, queue, restart service or promised percentage saving.

## 7. Troubleshooting

| Symptom | Check |
|---|---|
| `codex` not found | Install/update CLI; open a fresh terminal and check npm's executable path |
| Key missing / HTTP 401 | Set the key in the calling environment; verify it without publishing it |
| HTTP 429 | Check provider quota/rate limits; avoid unlimited retries |
| Model unavailable | Confirm the account/provider exposes the requested model |
| Image rejected | Update CLI/catalog; check image format, limits and `-ImagePath` |
| Unsupported reasoning | Use documented `low`, `high` or `max` for this Flash setup |
| Untrusted Git directory | Run in the intended Git working tree; inspect trust settings |
| TOML error | Remove duplicate keys/tables; keep root keys above table headers |
| Network/command denied | Inspect inner/outer sandbox and managed policies; do not blindly grant full access |
| Catalog error after update | Compare current official integration/schema and update the catalog |

## 8. Update or remove

Review changes, run `git pull --ff-only` in this setup repository, then rerun the
installer. Existing user config remains untouched. To remove the setup, remove only
the ProgramMoe worker/catalog/reviewer/example files, and deliberately undo settings
and AGENTS.md sections you added. Do not delete your entire `.codex` directory.

Remove a persistent user key only when other tools no longer need it:

```powershell
[Environment]::SetEnvironmentVariable('DEEPSEEK_API_KEY', $null, 'User')
Remove-Item Env:DEEPSEEK_API_KEY -ErrorAction SilentlyContinue
```

## References

Documentation checked 2026-09-16. Model availability and APIs can change.

- [OpenAI Astra](https://developers.openai.com/api/docs/models/gpt-6-astra)
- [Codex configuration](https://developers.openai.com/codex/config-reference/)
- [Codex subagents](https://developers.openai.com/codex/subagents/)
- [Codex CLI arguments](https://developers.openai.com/codex/cli/reference/)
- [DeepSeek Codex integration](https://api-docs.deepseek.com/quick_start/agent_integrations/codex/)
- [DeepSeek Responses API](https://api-docs.deepseek.com/guides/responses_api/)
- [Codex model metadata source](https://github.com/openai/codex/blob/main/codex-rs/protocol/src/openai_models.rs)
