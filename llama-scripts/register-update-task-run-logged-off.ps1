param(
    [string]$TaskName = "Update llama.cpp CUDA 13.x and restart server",
    [string]$BaseDir = (Split-Path -Parent $PSScriptRoot),
    [int]$DaysInterval = 3,
    [string]$At = "08:00"
)

$ErrorActionPreference = "Stop"

$Identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$Principal = [Security.Principal.WindowsPrincipal]::new($Identity)
$IsAdmin = $Principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $IsAdmin) {
    throw "Please run this script from an elevated PowerShell window: Run as administrator."
}

$ScriptPath = Join-Path $BaseDir "llama-scripts\update-llamacpp-cuda13.ps1"
if (-not (Test-Path $ScriptPath)) {
    throw "Update script not found: $ScriptPath"
}

$Action = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$ScriptPath`"" `
    -WorkingDirectory $BaseDir

$Trigger = New-ScheduledTaskTrigger `
    -Daily `
    -DaysInterval $DaysInterval `
    -At $At

$Settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries:$false `
    -DontStopIfGoingOnBatteries:$false `
    -StartWhenAvailable `
    -RunOnlyIfNetworkAvailable `
    -MultipleInstances IgnoreNew `
    -ExecutionTimeLimit (New-TimeSpan -Hours 2)

$TaskPrincipal = New-ScheduledTaskPrincipal `
    -UserId "$env:USERDOMAIN\$env:USERNAME" `
    -LogonType S4U `
    -RunLevel Highest

Register-ScheduledTask `
    -TaskName $TaskName `
    -Action $Action `
    -Trigger $Trigger `
    -Settings $Settings `
    -Principal $TaskPrincipal `
    -Description "Update llama.cpp Windows CUDA 13.x build and restart llama-server, even when the user is not logged on." `
    -Force | Out-Null

Get-ScheduledTask -TaskName $TaskName | Format-List TaskName,State,Principal,Actions,Triggers
Get-ScheduledTaskInfo -TaskName $TaskName | Format-List LastRunTime,LastTaskResult,NextRunTime
