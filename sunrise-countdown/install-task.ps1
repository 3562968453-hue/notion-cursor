#requires -Version 5.1
# Registers scheduled task "日出日落倒计时" (logon trigger).
# Does NOT use the Startup folder.
param(
    [string]$InstallDir = "",
    [string]$AhkExe = "",
    [switch]$SkipStart
)

$ErrorActionPreference = "Stop"
$TaskName = "日出日落倒计时"
$Here = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $InstallDir) {
    $InstallDir = Join-Path $env:USERPROFILE "Scripts"
}

function Find-AutoHotkeyU64 {
    param([string]$Hint)
    $candidates = @()
    if ($Hint) { $candidates += $Hint }
    if ($env:AUTOHOTKEY_U64) { $candidates += $env:AUTOHOTKEY_U64 }
    $cmd = Get-Command "AutoHotkeyU64.exe" -ErrorAction SilentlyContinue
    if ($cmd) { $candidates += $cmd.Source }

    $regPaths = @(
        "HKLM:\SOFTWARE\AutoHotkey",
        "HKLM:\SOFTWARE\WOW6432Node\AutoHotkey",
        "HKCU:\SOFTWARE\AutoHotkey"
    )
    foreach ($rp in $regPaths) {
        if (Test-Path $rp) {
            $installDir = (Get-ItemProperty $rp -ErrorAction SilentlyContinue).InstallDir
            if ($installDir) {
                $candidates += (Join-Path $installDir "AutoHotkeyU64.exe")
                $candidates += (Join-Path $installDir "v1.1.37.02\AutoHotkeyU64.exe")
            }
        }
    }

    $candidates += @(
        "$env:ProgramFiles\AutoHotkey\AutoHotkeyU64.exe",
        "$env:ProgramFiles\AutoHotkey\v1.1.37.02\AutoHotkeyU64.exe",
        "${env:ProgramFiles(x86)}\AutoHotkey\AutoHotkeyU64.exe",
        "D:\22-键盘快捷键2\软件\v1.1.37.02\AutoHotkeyU64.exe",
        "D:\22-jianpankuaijiejian2\ruanjian\v1.1.37.02\AutoHotkeyU64.exe"
    )

    foreach ($p in $candidates) {
        if ($p -and (Test-Path -LiteralPath $p)) { return (Resolve-Path -LiteralPath $p).Path }
    }
    return $null
}

Write-Host "Install dir: $InstallDir"
New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null

$srcAhk = Join-Path $Here "sunrise-countdown.ahk"
$srcIni = Join-Path $Here "sunrise-countdown.ini"
$dstAhk = Join-Path $InstallDir "sunrise-countdown.ahk"
$dstIni = Join-Path $InstallDir "sunrise-countdown.ini"

if (-not (Test-Path -LiteralPath $srcAhk)) {
    throw "Missing $srcAhk"
}

Copy-Item -LiteralPath $srcAhk -Destination $dstAhk -Force
if (Test-Path -LiteralPath $dstIni) {
    Write-Host "Keep existing ini: $dstIni"
} else {
    Copy-Item -LiteralPath $srcIni -Destination $dstIni -Force
    Write-Host "Wrote new-PC ini (city Beijing, no saved window pos): $dstIni"
}

$ahk = Find-AutoHotkeyU64 -Hint $AhkExe
if (-not $ahk) {
    throw @"
AutoHotkeyU64.exe not found.
Install AutoHotkey v1.1 64-bit, then re-run:
  .\install-task.ps1 -AhkExe 'C:\Path\To\AutoHotkeyU64.exe'
"@
}
Write-Host "AutoHotkeyU64: $ahk"

$arg = '"' + $dstAhk + '"'
$action = New-ScheduledTaskAction -Execute $ahk -Argument $arg -WorkingDirectory $InstallDir
$trigger = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
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
    -Trigger $trigger `
    -Principal $principal `
    -Settings $settings `
    -Description "登录后立刻显示日出日落倒计时，不走启动文件夹排队。" `
    -Force | Out-Null

Write-Host "Scheduled task registered: $TaskName"

Get-CimInstance Win32_Process -Filter "Name = 'AutoHotkeyU64.exe'" -ErrorAction SilentlyContinue |
    Where-Object { $_.CommandLine -and ($_.CommandLine -like "*sunrise-countdown.ahk*") } |
    ForEach-Object {
        Write-Host "Restarting existing sunrise-countdown instance (PID $($_.ProcessId))"
        Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue
    }

if (-not $SkipStart) {
    Start-Process -FilePath $ahk -ArgumentList $arg -WorkingDirectory $InstallDir
    Write-Host "Started overlay."
}

Write-Host "Done. Startup folder was not used."
Write-Host "Tray: city / always-on-top / exit. Hover for mist plaque."
