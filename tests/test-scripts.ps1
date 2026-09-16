#requires -Version 5.1
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
function Assert-True($Value, [string]$Message) {
    if (-not $Value) { throw "FAILED: $Message" }
    Write-Host "PASS: $Message"
}
Get-ChildItem -Path $root -Filter '*.ps1' -Recurse | ForEach-Object {
    $tokens = $null; $parseErrors = $null
    $null = [Management.Automation.Language.Parser]::ParseFile($_.FullName, [ref]$tokens, [ref]$parseErrors)
    Assert-True ($parseErrors.Count -eq 0) "PowerShell syntax: $($_.Name)"
}
$temp = Join-Path ([IO.Path]::GetTempPath()) ('programmoe-test-' + [guid]::NewGuid().ToString('N'))
$oldHome = $env:CODEX_HOME; $oldKey = $env:DEEPSEEK_API_KEY
try {
    $null = New-Item -ItemType Directory -Path $temp
    $env:CODEX_HOME = Join-Path $temp 'codex home'
    $null = New-Item -ItemType Directory -Path $env:CODEX_HOME
    $existingConfig = Join-Path $env:CODEX_HOME 'config.toml'
    [IO.File]::WriteAllText($existingConfig, '# keep existing settings')
    & (Join-Path $root 'scripts/install.ps1')
    Assert-True (([IO.File]::ReadAllText($existingConfig)) -eq '# keep existing settings') 'Installer preserves existing config'
    $launcher = Join-Path $env:CODEX_HOME 'bin/deepseek-agent.ps1'
    Assert-True (Test-Path -LiteralPath $launcher) 'Worker installed'
    foreach ($role in @('researcher', 'worker', 'writer')) {
        $result = & $launcher -Role $role -Task 'Test only' -ProjectPath $root -DryRun | ConvertFrom-Json
        $expected = if ($role -eq 'worker') { 'workspace-write' } else { 'read-only' }
        Assert-True ($result.Sandbox -eq $expected) "Sandbox for $role"
    }
    $taskFile = Join-Path $temp 'task.txt'
    $taskText = ([string][char]0x0E44 + [char]0x0E17 + [char]0x0E22) + ' "quoted" $literal; not a command'
    [IO.File]::WriteAllText($taskFile, $taskText, (New-Object Text.UTF8Encoding($false)))
    $image = Join-Path $temp 'test image.png'
    [IO.File]::WriteAllBytes($image, [Convert]::FromBase64String('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aWZkAAAAASUVORK5CYII='))
    $result = & $launcher -Role researcher -TaskFile $taskFile -ProjectPath $root -ImagePath $image -DryRun | ConvertFrom-Json
    Assert-True ($result.ImageCount -eq 1) 'Image option is forwarded'
    Assert-True ($result.Arguments -contains 'agents.enabled=false') 'Workers disable native delegation'
    Assert-True ($result.Arguments -contains '-') 'Task uses stdin'
    $env:DEEPSEEK_API_KEY = 'test-placeholder-not-a-real-key'
    $script:mockExit = 0
    function global:codex {
        $script:capturedArgs = @($args)
        $script:capturedPrompt = $input | Out-String
        $global:LASTEXITCODE = $script:mockExit
        'MOCK_WORKER_OK'
    }
    $null = & $launcher -Role researcher -TaskFile $taskFile -ProjectPath $root
    Assert-True ($script:capturedPrompt.Contains($taskText)) 'Unicode and quoted task preserved in stdin'
    Assert-True ($script:capturedArgs -contains 'model_provider=deepseek') 'Explicit child provider'
    $script:mockExit = 7; $failed = $false
    try { $null = & $launcher -Role researcher -Task 'Failure check' -ProjectPath $root } catch { $failed = $true }
    Assert-True $failed 'Nonzero CLI exit causes failure'
    $env:DEEPSEEK_API_KEY = ''; $failed = $false
    try { $null = & $launcher -Role researcher -Task 'Key check' -ProjectPath $root } catch { $failed = $true }
    Assert-True $failed 'Missing key is rejected'
    [IO.File]::AppendAllText($launcher, "`n# changed fixture")
    & (Join-Path $root 'scripts/install.ps1')
    Assert-True (@(Get-ChildItem -LiteralPath (Split-Path -Parent $launcher) -Filter '*.bak').Count -gt 0) 'Changed files are backed up'
    $freshHome = Join-Path $temp 'fresh home'
    & (Join-Path $root 'scripts/install.ps1') -CodexHome $freshHome
    Assert-True (Test-Path -LiteralPath (Join-Path $freshHome 'config.toml')) 'Fresh config is created'
} finally {
    Remove-Item Function:\codex -ErrorAction SilentlyContinue
    $env:CODEX_HOME = $oldHome; $env:DEEPSEEK_API_KEY = $oldKey
    if (Test-Path -LiteralPath $temp) { Remove-Item -LiteralPath $temp -Recurse -Force }
}
Write-Host 'All offline PowerShell checks passed. No real API calls were made.'
