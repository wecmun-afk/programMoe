#requires -Version 5.1
[CmdletBinding()]
param(
    [string]$CodexHome = $(if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $HOME '.codex' })
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$sourceRoot = Split-Path -Parent $PSScriptRoot
$files = @{
    'scripts/deepseek-agent.ps1' = 'bin/deepseek-agent.ps1'
    '.codex/agents/final-reviewer.toml' = 'agents/final-reviewer.toml'
    'config/deepseek-models.json' = 'programmoe/deepseek-models.json'
    '.codex/config.example.toml' = 'config.programmoe.example.toml'
}
foreach ($source in $files.Keys) {
    if (-not (Test-Path -LiteralPath (Join-Path $sourceRoot $source) -PathType Leaf)) { throw "Package is incomplete: $source" }
}
$null = Get-Content -LiteralPath (Join-Path $sourceRoot 'config/deepseek-models.json') -Raw | ConvertFrom-Json
$null = New-Item -ItemType Directory -Force -Path $CodexHome
$CodexHome = (Resolve-Path -LiteralPath $CodexHome).ProviderPath
foreach ($source in $files.Keys) {
    $from = Join-Path $sourceRoot $source
    $to = Join-Path $CodexHome $files[$source]
    $null = New-Item -ItemType Directory -Force -Path (Split-Path -Parent $to)
    if (Test-Path -LiteralPath $to -PathType Leaf) {
        if ((Get-FileHash -LiteralPath $from).Hash -eq (Get-FileHash -LiteralPath $to).Hash) { continue }
        $backup = $to + '.' + [guid]::NewGuid().ToString('N') + '.bak'
        Copy-Item -LiteralPath $to -Destination $backup -ErrorAction Stop
        Write-Host "Backed up: $backup"
    }
    Copy-Item -LiteralPath $from -Destination $to -Force -ErrorAction Stop
}
$config = Join-Path $CodexHome 'config.toml'
if (Test-Path -LiteralPath $config) {
    Write-Host 'Existing config.toml was NOT changed.'
    Write-Host 'Merge the desired Astra settings from config.programmoe.example.toml manually.'
} else {
    Copy-Item -LiteralPath (Join-Path $sourceRoot '.codex/config.example.toml') -Destination $config
    Write-Host 'Created config.toml with Astra medium as the root.'
}
Write-Host "Installed into: $CodexHome"
Write-Host 'Next: configure your local API key, restart your IDE, and add AGENTS.md to your project.'
Write-Host 'This installer does not install Codex, perform login, run models, or change AGENTS.md.'
