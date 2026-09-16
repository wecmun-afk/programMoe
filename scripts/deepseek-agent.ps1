#requires -Version 5.1
[CmdletBinding(DefaultParameterSetName = 'Inline')]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('researcher', 'worker', 'writer')]
    [string]$Role,
    [Parameter(Mandatory = $true, ParameterSetName = 'Inline')]
    [ValidateNotNullOrEmpty()]
    [string]$Task,
    [Parameter(Mandatory = $true, ParameterSetName = 'File')]
    [string]$TaskFile,
    [string]$ProjectPath = (Get-Location).Path,
    [ValidateSet('low', 'high', 'max')]
    [string]$ReasoningEffort = 'low',
    [string[]]$ImagePath = @(),
    [switch]$DryRun
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$workspace = (Resolve-Path -LiteralPath $ProjectPath).ProviderPath
if (-not (Test-Path -LiteralPath $workspace -PathType Container)) {
    throw 'ProjectPath must be a directory.'
}
function Resolve-InputFile([string]$Path) {
    if (-not [IO.Path]::IsPathRooted($Path)) { $Path = Join-Path $workspace $Path }
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw "Input file does not exist: $Path" }
    return (Resolve-Path -LiteralPath $Path).ProviderPath
}
if ($PSCmdlet.ParameterSetName -eq 'File') {
    $Task = [IO.File]::ReadAllText((Resolve-InputFile $TaskFile), [Text.Encoding]::UTF8)
}
if ([string]::IsNullOrWhiteSpace($Task)) { throw 'The task must not be blank.' }
$codexHome = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $HOME '.codex' }
$catalog = Join-Path $codexHome 'programmoe/deepseek-models.json'
if (-not (Test-Path -LiteralPath $catalog -PathType Leaf)) {
    $catalog = Join-Path (Split-Path -Parent $PSScriptRoot) 'config/deepseek-models.json'
}
if (-not (Test-Path -LiteralPath $catalog -PathType Leaf)) {
    throw 'Missing model catalog. Run scripts/install.ps1 first.'
}
$catalog = (Resolve-Path -LiteralPath $catalog).ProviderPath.Replace('\', '/')
$sandbox = if ($Role -eq 'worker') { 'workspace-write' } else { 'read-only' }
$instructions = @{
    researcher = 'Inspect relevant repository files and supplied evidence. Do not modify files. Return findings, paths, uncertainties and sources. Built-in web search is disabled; do not pretend to have browsed.'
    worker = 'Implement only the bounded task. Inspect before editing; preserve unrelated changes. Run relevant available tests. Report files changed, commands, results and unresolved issues. Do not commit or push.'
    writer = 'Draft documentation or summaries using verified repository evidence. Return the draft without editing files. Do not claim unavailable tests passed.'
}
$prompt = @"
You are the $Role worker, NOT the root orchestrator.
Do not spawn subagents or invoke another agent launcher.
Never print API keys, credentials or environment dumps.
$($instructions[$Role])

TASK:
$Task
"@
# Codex accepts non-TOML -c values as literal strings. Avoid embedded double
# quotes here so Windows PowerShell 5.1/npm shims preserve paths with spaces.
# All overrides apply only to this child process, not the Astra parent.
$arguments = @(
    'exec', '-C', $workspace, '--sandbox', $sandbox,
    '-c', 'model_provider=deepseek',
    '-c', 'model=deepseek-flash',
    '-c', ('model_reasoning_effort=' + $ReasoningEffort),
    '-c', 'model_reasoning_summary=none',
    '-c', 'web_search=disabled',
    '-c', 'approval_policy=never',
    '-c', 'features.multi_agent=false',
    '-c', 'agents.enabled=false',
    '-c', ('model_catalog_json=' + $catalog),
    '-c', 'model_providers.deepseek.name=DeepSeek',
    '-c', 'model_providers.deepseek.base_url=https://api.deepseek.com',
    '-c', 'model_providers.deepseek.env_key=DEEPSEEK_API_KEY',
    '-c', 'model_providers.deepseek.wire_api=responses',
    '-c', 'model_providers.deepseek.requires_openai_auth=false'
)
foreach ($image in $ImagePath) {
    $resolved = Resolve-InputFile $image
    if ($resolved.Contains(',')) { throw 'Rename image files whose paths contain commas.' }
    $arguments += @('--image', $resolved)
}
$arguments += '-'
if ($DryRun) {
    [pscustomobject]@{
        Role = $Role; Sandbox = $sandbox; ProjectPath = $workspace
        Model = 'deepseek-flash'; ReasoningEffort = $ReasoningEffort
        ImageCount = $ImagePath.Count; Arguments = $arguments
    } | ConvertTo-Json -Depth 5
    return
}
if ([string]::IsNullOrWhiteSpace($env:DEEPSEEK_API_KEY)) {
    throw 'DEEPSEEK_API_KEY is not set. Set it locally and restart your terminal/IDE.'
}
$null = Get-Command codex -ErrorAction Stop
$previousEncoding = $OutputEncoding
try {
    # Send task text over stdin; never evaluate it as a shell command.
    $OutputEncoding = New-Object System.Text.UTF8Encoding($false)
    $prompt | & codex @arguments
    if ($LASTEXITCODE -ne 0) { throw "Codex worker failed with exit code $LASTEXITCODE. Inspect the error above." }
} finally {
    $OutputEncoding = $previousEncoding
}
