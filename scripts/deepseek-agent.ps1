param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("researcher","worker","writer")]
    [string]$Role,

    [Parameter(Mandatory=$true)]
    [string]$Task
)

$instructions = @{
    researcher = @"
You are the RESEARCHER subagent.
Investigate the repository and requested topic.
Focus on relevant files, dependencies, evidence, risks and possible solutions.
Do not modify project files.
Return concise findings to the parent agent.
"@

    worker = @"
You are the IMPLEMENTATION WORKER.
Implement the bounded task you receive.
Inspect existing code before editing.
Keep changes focused.
Run relevant tests when possible.
Report files changed, tests run and remaining issues.
"@

    writer = @"
You are the WRITER subagent.
Produce documentation, summaries, comments, migration notes or technical writing.
Do not make unrelated code changes.
Return concise output to the parent agent.
"@
}

$Sandbox = if ($Role -eq "worker") { "workspace-write" } else { "read-only" }

$Prompt = @"
$($instructions[$Role])

TASK:
$Task
"@

codex exec `
    -C (Get-Location).Path `
    --sandbox $Sandbox `
    -c 'model_provider="deepseek"' `
    -c 'model="deepseek-flash"' `
    $Prompt
