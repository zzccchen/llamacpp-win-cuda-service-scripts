$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "llama-common.ps1")

$BaseDir = Get-LlamaProjectRoot -ScriptsDir $PSScriptRoot
$CurrentDir = Join-Path $BaseDir "llama-current"
$ConfigPath = Join-Path $BaseDir "llama-config\models.ini"
$RuntimeDir = Join-Path $BaseDir "llama-runtime"
$LogDir = Join-Path $BaseDir "llama-logs"

$HostName = "127.0.0.1"
$Port = 8080

# 空闲多少秒后自动 sleep / 卸载模型。
# 900 = 15 分钟；你也可以改成 1800 或 3600。
$SleepIdleSeconds = 1800

$PidFile = Join-Path $RuntimeDir "llama-server.pid"
$StdOutLog = Join-Path $LogDir "llama-server.out.log"
$StdErrLog = Join-Path $LogDir "llama-server.err.log"

New-Item -ItemType Directory -Path $RuntimeDir -Force | Out-Null
New-Item -ItemType Directory -Path $LogDir -Force | Out-Null

function Test-LlamaServerAlive {
    try {
        Invoke-WebRequest `
            -Uri "http://$HostName`:$Port/health" `
            -UseBasicParsing `
            -TimeoutSec 2 | Out-Null

        return $true
    }
    catch {
        return $false
    }
}

if (Test-LlamaServerAlive) {
    Write-Host "llama-server is already running at http://$HostName`:$Port"
    exit 0
}

$ExePath = Join-Path $CurrentDir "llama-server.exe"

if (-not (Test-Path $ExePath)) {
    throw "llama-server.exe not found: $ExePath. Please run update-llamacpp-cuda13.ps1 first."
}

if (-not (Test-Path $ConfigPath)) {
    throw "models.ini not found: $ConfigPath"
}

$Args = @(
    "--host", $HostName,
    "--port", "$Port",
    "--models-preset", $ConfigPath,
    "--models-max", "1",
    "--sleep-idle-seconds", "$SleepIdleSeconds"
)

Write-Host "Starting llama-server..."
Write-Host "$ExePath $($Args -join ' ')"

$Process = Start-Process `
    -FilePath $ExePath `
    -ArgumentList $Args `
    -WorkingDirectory $CurrentDir `
    -WindowStyle Hidden `
    -RedirectStandardOutput $StdOutLog `
    -RedirectStandardError $StdErrLog `
    -PassThru

Set-Content -Path $PidFile -Value $Process.Id

for ($i = 1; $i -le 60; $i++) {
    Start-Sleep -Seconds 1

    if (Test-LlamaServerAlive) {
        Write-Host "llama-server started: http://$HostName`:$Port"
        exit 0
    }

    if ($Process.HasExited) {
        throw "llama-server exited early. Check log: $StdErrLog"
    }
}

throw "llama-server did not become healthy within 60 seconds. Check logs in $LogDir"
