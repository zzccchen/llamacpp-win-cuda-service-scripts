$ErrorActionPreference = "Stop"

$StopScript = Join-Path $PSScriptRoot "stop-llamacpp-server.ps1"
$StartScript = Join-Path $PSScriptRoot "start-llamacpp-server.ps1"

if (-not (Test-Path $StopScript)) {
    throw "Stop script not found: $StopScript"
}

if (-not (Test-Path $StartScript)) {
    throw "Start script not found: $StartScript"
}

Write-Host "Restarting llama-server..."

powershell.exe -NoProfile -ExecutionPolicy Bypass -File $StopScript
if ($LASTEXITCODE -ne 0) {
    throw "Stop script failed with exit code $LASTEXITCODE."
}

powershell.exe -NoProfile -ExecutionPolicy Bypass -File $StartScript
if ($LASTEXITCODE -ne 0) {
    throw "Start script failed with exit code $LASTEXITCODE."
}

Write-Host "llama-server restarted."
