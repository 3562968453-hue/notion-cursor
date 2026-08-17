#requires -Version 5.1
# Pull this git clone, then start/restart the overlay if the script changed.
# Machine ini (window/city) is local and is not overwritten.
param(
    [string]$AhkExe = "",
    [switch]$Start,
    [switch]$SkipPull
)

$ErrorActionPreference = "Stop"
$Here = Split-Path -Parent $MyInvocation.MyCommand.Path
$OverlayDir = $Here
. (Join-Path $Here "common.ps1")

$log = Join-Path $Here "update.log"
try { Start-Transcript -Path $log -Append -Force | Out-Null } catch { }

try {
    Ensure-LocalIni | Out-Null
    $changed = $false
    if (-not $SkipPull) {
        $changed = [bool](Sync-FromGit)
        if ($changed) { Write-Host "sunrise-countdown.ahk changed on pull." }
    }

    $exe = Find-AutoHotkeyU64 -Hint $AhkExe
    if ($exe) { Write-MachineConfig -AhkExe $exe }

    $running = @(Get-OverlayProcesses)
    if ($Start) {
        if ($changed -or $running.Count -eq 0) {
            Stop-Overlay
            Start-Sleep -Milliseconds 400
            Start-Overlay -AhkExe $exe
        } else {
            Write-Host "Overlay already running; script unchanged."
        }
    } elseif ($changed) {
        Stop-Overlay
        Start-Sleep -Milliseconds 400
        Start-Overlay -AhkExe $exe
    } else {
        Write-Host "Pulled. Overlay not restarted (no script change). Pass -Start to ensure it is running."
    }
} catch {
    Write-Host $_
    Write-UpdateLog $_
    throw
} finally {
    try { Stop-Transcript | Out-Null } catch { }
}
