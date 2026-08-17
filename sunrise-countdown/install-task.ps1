#requires -Version 5.1
# Register scheduled task "日出日落倒计时".
# Runs from THIS git clone (so cloud-agent pushes sync via git pull).
# Does NOT use the Startup folder.
param(
    [string]$AhkExe = "",
    [int]$SyncMinutes = 20,
    [switch]$SkipStart
)

$ErrorActionPreference = "Stop"
$Here = Split-Path -Parent $MyInvocation.MyCommand.Path
$OverlayDir = $Here
. (Join-Path $Here "common.ps1")

$ahkFile = Get-AhkPath
if (-not (Test-Path -LiteralPath $ahkFile)) { throw "Missing $ahkFile" }
Ensure-LocalIni | Out-Null

$exe = Find-AutoHotkeyU64 -Hint $AhkExe
if (-not $exe) {
    throw @"
AutoHotkeyU64.exe not found.
Install AutoHotkey v1.1 64-bit, then re-run:
  .\install-task.ps1 -AhkExe 'C:\Path\To\AutoHotkeyU64.exe'
"@
}
Write-MachineConfig -AhkExe $exe
Write-Host "AutoHotkeyU64: $exe"
Write-Host "Overlay dir (git clone): $Here"

$repo = Get-RepoRoot
if ($repo) {
    Write-Host "Repo root: $repo"
} else {
    Write-Host "WARNING: this folder is not inside a git clone. Multi-PC sync needs: git clone this GitHub repo, then run install-task here."
}

$updatePs1 = Join-Path $Here "update.ps1"
$ps = Join-Path $env:SystemRoot "System32\WindowsPowerShell\v1.0\powershell.exe"
$arg = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$updatePs1`" -Start"
$action = New-ScheduledTaskAction -Execute $ps -Argument $arg -WorkingDirectory $Here

$triggers = @()
$triggers += (New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME)
if ($SyncMinutes -gt 0) {
    $startAt = (Get-Date).AddMinutes(1)
    $rep = New-ScheduledTaskTrigger -Once -At $startAt -RepetitionInterval (New-TimeSpan -Minutes $SyncMinutes) -RepetitionDuration ([TimeSpan]::FromDays(3650))
    $triggers += $rep
    Write-Host "Also pull every $SyncMinutes minutes."
}

$principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Limited
$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -ExecutionTimeLimit ([TimeSpan]::Zero) `
    -MultipleInstances IgnoreNew `
    -StartWhenAvailable `
    -Priority 4
$settings.DisallowStartIfOnBatteries = $false
$settings.StopIfGoingOnBatteries = $false
try { $settings.AllowHardTerminate = $false } catch { }

Register-ScheduledTask `
    -TaskName $TaskName `
    -Action $action `
    -Trigger $triggers `
    -Principal $principal `
    -Settings $settings `
    -Description "登录后 git pull 再显示日出日落倒计时；不走启动文件夹。云端 Agent 改的是 GitHub，各台从 clone 拉取。" `
    -Force | Out-Null

Write-Host "Scheduled task registered: $TaskName"

if (-not $SkipStart) {
    & $updatePs1 -Start -AhkExe $exe
}

Write-Host "Done. Startup folder was not used."
Write-Host "Each PC should git clone the same repo and run this installer once."
