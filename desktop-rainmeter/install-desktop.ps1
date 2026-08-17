#requires -Version 5.1
# Copy the desktop Rainmeter widgets from this repo onto this PC and load the layout.
$ErrorActionPreference = "Stop"
$Here = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoSkins = Join-Path $Here "Skins"
$RepoLayout = Join-Path $Here "Layouts\DesktopWidgets"

if (-not (Test-Path -LiteralPath $RepoSkins)) { throw "Missing $RepoSkins" }

function Get-RainmeterExe {
    $cands = @(
        "$env:ProgramFiles\Rainmeter\Rainmeter.exe",
        "${env:ProgramFiles(x86)}\Rainmeter\Rainmeter.exe",
        "$env:LOCALAPPDATA\Programs\Rainmeter\Rainmeter.exe"
    )
    foreach ($p in $cands) {
        if ($p -and (Test-Path -LiteralPath $p)) { return $p }
    }
    $proc = Get-Process Rainmeter -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($proc -and $proc.Path) { return $proc.Path }
    return $null
}

function Get-SkinPath {
    $ini = Join-Path $env:APPDATA "Rainmeter\Rainmeter.ini"
    if (Test-Path -LiteralPath $ini) {
        foreach ($line in Get-Content -LiteralPath $ini -Encoding UTF8) {
            if ($line -match '^\s*SkinPath=(.+)$') {
                return $Matches[1].Trim()
            }
        }
    }
    return (Join-Path $env:USERPROFILE "Documents\Rainmeter\Skins\")
}

$exe = Get-RainmeterExe
if (-not $exe) {
    throw @"
未找到 Rainmeter。请先安装：https://www.rainmeter.net/
装好后再双击 install-desktop.bat
"@
}

$skinPath = Get-SkinPath
if (-not $skinPath.EndsWith("\") -and -not $skinPath.EndsWith("/")) { $skinPath += "\" }
New-Item -ItemType Directory -Force -Path $skinPath | Out-Null
Write-Host "Rainmeter: $exe"
Write-Host "SkinPath: $skinPath"

Get-ChildItem -LiteralPath $RepoSkins -Directory | ForEach-Object {
    $dest = Join-Path $skinPath $_.Name
    Write-Host "Copy skin $($_.Name)"
    if (Test-Path -LiteralPath $dest) { Remove-Item -LiteralPath $dest -Recurse -Force }
    Copy-Item -LiteralPath $_.FullName -Destination $dest -Recurse -Force
}

$layoutDest = Join-Path $env:APPDATA "Rainmeter\Layouts\DesktopWidgets"
New-Item -ItemType Directory -Force -Path $layoutDest | Out-Null
Copy-Item -LiteralPath (Join-Path $RepoLayout "Rainmeter.ini") -Destination (Join-Path $layoutDest "Rainmeter.ini") -Force
Write-Host "Layout copied: $layoutDest"

& $exe "!LoadLayout" "DesktopWidgets"
Write-Host "Done. Loaded layout DesktopWidgets."
Write-Host "If a widget is off-screen on another monitor layout, drag it. Positions follow the original PC."
