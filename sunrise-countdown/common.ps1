#requires -Version 5.1
$TaskName = "日出日落倒计时"
if (-not $OverlayDir) {
    if ($PSScriptRoot) { $OverlayDir = $PSScriptRoot }
    else { $OverlayDir = Split-Path -Parent $MyInvocation.MyCommand.Path }
}

function Get-RepoRoot {
    param([string]$Start = $OverlayDir)
    $d = $Start
    while ($d) {
        if (Test-Path -LiteralPath (Join-Path $d ".git")) { return $d }
        $parent = Split-Path $d -Parent
        if (-not $parent -or $parent -eq $d) { break }
        $d = $parent
    }
    return $null
}

function Get-MachineJsonPath {
    return (Join-Path $OverlayDir "machine.local.json")
}

function Read-MachineConfig {
    $p = Get-MachineJsonPath
    if (-not (Test-Path -LiteralPath $p)) { return $null }
    try { return (Get-Content -LiteralPath $p -Raw -Encoding UTF8 | ConvertFrom-Json) } catch { return $null }
}

function Write-MachineConfig {
    param([string]$AhkExe)
    $obj = @{ AhkExe = $AhkExe }
    $json = $obj | ConvertTo-Json
    [System.IO.File]::WriteAllText((Get-MachineJsonPath), $json, (New-Object System.Text.UTF8Encoding $false))
}

function Find-AutoHotkeyU64 {
    param([string]$Hint)
    $candidates = @()
    if ($Hint) { $candidates += $Hint }
    $saved = Read-MachineConfig
    if ($saved -and $saved.AhkExe) { $candidates += [string]$saved.AhkExe }
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
        (Join-Path $OverlayDir "runtime\AutoHotkeyU64.exe"),
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

function Get-AhkPath {
    return (Join-Path $OverlayDir "sunrise-countdown.ahk")
}

function Ensure-LocalIni {
    $ini = Join-Path $OverlayDir "sunrise-countdown.ini"
    $example = Join-Path $OverlayDir "sunrise-countdown.ini.example"
    if (Test-Path -LiteralPath $ini) { return $ini }
    if (Test-Path -LiteralPath $example) {
        Copy-Item -LiteralPath $example -Destination $ini
        Write-Host "Wrote local ini from example (not synced): $ini"
    }
    return $ini
}

function Get-OverlayProcesses {
    Get-CimInstance Win32_Process -Filter "Name = 'AutoHotkeyU64.exe'" -ErrorAction SilentlyContinue |
        Where-Object { $_.CommandLine -and ($_.CommandLine -like "*sunrise-countdown.ahk*") }
}

function Stop-Overlay {
    Get-OverlayProcesses | ForEach-Object {
        Write-Host "Stopping sunrise-countdown (PID $($_.ProcessId))"
        Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue
    }
}

function Start-Overlay {
    param([string]$AhkExe)
    $ahkFile = Get-AhkPath
    if (-not (Test-Path -LiteralPath $ahkFile)) { throw "Missing $ahkFile" }
    if (-not $AhkExe) { $AhkExe = Find-AutoHotkeyU64 }
    if (-not $AhkExe) { throw "AutoHotkeyU64.exe not found" }
    $arg = '"' + $ahkFile + '"'
    Start-Process -FilePath $AhkExe -ArgumentList $arg -WorkingDirectory $OverlayDir
    Write-Host "Started overlay: $ahkFile"
}

function Sync-FromGit {
    $repo = Get-RepoRoot
    if (-not $repo) {
        Write-Host "Not a git clone; skip pull (copy-only folder)."
        return $false
    }
    $git = Get-Command git -ErrorAction SilentlyContinue
    if (-not $git) {
        Write-Host "git not on PATH; skip pull."
        return $false
    }
    $before = ""
    $ahkFile = Get-AhkPath
    if (Test-Path -LiteralPath $ahkFile) {
        $before = (Get-FileHash -LiteralPath $ahkFile -Algorithm SHA256).Hash
    }
    Write-Host "git pull in $repo"
    Push-Location $repo
    try {
        $out = & git pull --ff-only 2>&1 | Out-String
        Write-Host $out
        if ($LASTEXITCODE -ne 0) {
            $out = & git pull --ff-only origin main 2>&1 | Out-String
            Write-Host $out
        }
    } finally {
        Pop-Location
    }
    $after = ""
    if (Test-Path -LiteralPath $ahkFile) {
        $after = (Get-FileHash -LiteralPath $ahkFile -Algorithm SHA256).Hash
    }
    return ($before -and $after -and $before -ne $after)
}

function Write-UpdateLog {
    param([string]$Text)
    $log = Join-Path $OverlayDir "update.log"
    $line = "{0} {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Text
    Add-Content -LiteralPath $log -Value $line -Encoding UTF8
}
