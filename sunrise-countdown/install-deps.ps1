#requires -Version 5.1
# Install AutoHotkey v1.1.37.02 64-bit (portable AutoHotkeyU64.exe)
# and font "霞鹜文楷 轻便版 Medium" (LXGW WenKai Lite Medium).
# Windows only. Does not use the Startup folder.
param(
    [switch]$SkipFont,
    [switch]$SkipAhk
)

$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$Here = Split-Path -Parent $MyInvocation.MyCommand.Path
$OverlayDir = $Here
. (Join-Path $Here "common.ps1")

$Runtime = Join-Path $Here "runtime"
New-Item -ItemType Directory -Force -Path $Runtime | Out-Null

$AhkZipUrl = "https://github.com/AutoHotkey/AutoHotkey/releases/download/v1.1.37.02/AutoHotkey_1.1.37.02.zip"
$AhkZipHash = "6f3663f7cdd25063c8c8728f5d9b07813ced8780522fd1f124ba539e2854215f"
$FontUrl = "https://github.com/lxgw/LxgwWenKai-Lite/releases/download/v1.522/LXGWWenKaiLite-Medium.ttf"
$FontHash = "02eb0f8deed11b00481393f5720630ae1a44424f37f4157ea160a69a1c72a0b6"
$FontFaceZh = "霞鹜文楷 轻便版 Medium"
$FontFaceEn = "LXGW WenKai Lite Medium"

function Get-Sha256Lower {
    param([string]$Path)
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}

function Download-Verified {
    param([string]$Url, [string]$OutFile, [string]$ExpectedSha256)
    if ((Test-Path -LiteralPath $OutFile) -and ((Get-Sha256Lower $OutFile) -eq $ExpectedSha256)) {
        Write-Host "Already have $OutFile"
        return
    }
    Write-Host "Downloading $Url"
    $tmp = "$OutFile.partial"
    Invoke-WebRequest -Uri $Url -OutFile $tmp -UseBasicParsing
    $got = Get-Sha256Lower $tmp
    if ($got -ne $ExpectedSha256) {
        Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
        throw "Hash mismatch for $OutFile`nexpected $ExpectedSha256`ngot      $got"
    }
    Move-Item -LiteralPath $tmp -Destination $OutFile -Force
}

function Install-PortableAhk {
    $destExe = Join-Path $Runtime "AutoHotkeyU64.exe"
    if (Test-Path -LiteralPath $destExe) {
        Write-Host "AutoHotkeyU64 already in runtime: $destExe"
        Write-MachineConfig -AhkExe $destExe
        return $destExe
    }
    $existing = Find-AutoHotkeyU64
    if ($existing) {
        Write-Host "Found AutoHotkeyU64: $existing"
        Write-MachineConfig -AhkExe $existing
        return $existing
    }
    $zip = Join-Path $Runtime "AutoHotkey_1.1.37.02.zip"
    Download-Verified -Url $AhkZipUrl -OutFile $zip -ExpectedSha256 $AhkZipHash
    $extract = Join-Path $Runtime "ahk-extract"
    if (Test-Path -LiteralPath $extract) { Remove-Item -LiteralPath $extract -Recurse -Force }
    Expand-Archive -LiteralPath $zip -DestinationPath $extract -Force
    $found = Get-ChildItem -LiteralPath $extract -Filter "AutoHotkeyU64.exe" -Recurse | Select-Object -First 1
    if (-not $found) { throw "AutoHotkeyU64.exe missing from zip" }
    Copy-Item -LiteralPath $found.FullName -Destination $destExe -Force
    Write-Host "Installed portable AutoHotkey v1.1.37.02 64-bit: $destExe"
    Write-MachineConfig -AhkExe $destExe
    return $destExe
}

function Test-FontInstalled {
    Add-Type -AssemblyName System.Drawing -ErrorAction SilentlyContinue
    $names = @()
    try {
        $names = @((New-Object System.Drawing.Text.InstalledFontCollection).Families | ForEach-Object { $_.Name })
    } catch { }
    return ($names -contains $FontFaceZh) -or ($names -contains $FontFaceEn)
}

function Install-UserFont {
    if (Test-FontInstalled) {
        Write-Host "Font already installed: $FontFaceZh"
        return
    }
    $ttf = Join-Path $Runtime "LXGWWenKaiLite-Medium.ttf"
    Download-Verified -Url $FontUrl -OutFile $ttf -ExpectedSha256 $FontHash
    $fontDir = Join-Path $env:LOCALAPPDATA "Microsoft\Windows\Fonts"
    New-Item -ItemType Directory -Force -Path $fontDir | Out-Null
    $dest = Join-Path $fontDir "LXGWWenKaiLite-Medium.ttf"
    Copy-Item -LiteralPath $ttf -Destination $dest -Force

    $reg = "HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"
    if (-not (Test-Path $reg)) { New-Item -Path $reg -Force | Out-Null }
    New-ItemProperty -Path $reg -Name "$FontFaceZh (TrueType)" -Value $dest -PropertyType String -Force | Out-Null
    New-ItemProperty -Path $reg -Name "$FontFaceEn (TrueType)" -Value $dest -PropertyType String -Force | Out-Null

    $sig = @'
using System;
using System.Runtime.InteropServices;
public static class FontNotify {
  [DllImport("gdi32.dll", CharSet = CharSet.Unicode)]
  public static extern int AddFontResourceEx(string lpszFilename, uint fl, IntPtr pdv);
  [DllImport("user32.dll", CharSet = CharSet.Unicode)]
  public static extern int SendMessageTimeout(IntPtr hWnd, uint Msg, IntPtr wParam, IntPtr lParam, uint fuFlags, uint uTimeout, out IntPtr lpdwResult);
}
'@
    Add-Type -TypeDefinition $sig -ErrorAction SilentlyContinue
    try {
        [void][FontNotify]::AddFontResourceEx($dest, 0, [IntPtr]::Zero)
        $hwndBroadcast = [IntPtr]0xffff
        $r = [IntPtr]::Zero
        [void][FontNotify]::SendMessageTimeout($hwndBroadcast, 0x001D, [IntPtr]::Zero, [IntPtr]::Zero, 0, 1000, [ref]$r)
    } catch { }

    Write-Host "Installed font for current user: $FontFaceZh"
    Write-Host "  $dest"
}

if ($env:OS -ne "Windows_NT") {
    throw "This installer is for Windows. This machine is not Windows_NT."
}

if (-not $SkipAhk) { [void](Install-PortableAhk) }
if (-not $SkipFont) { Install-UserFont }

Write-Host "Deps done. Next: install-task.bat  (scheduled task, not Startup folder)"
