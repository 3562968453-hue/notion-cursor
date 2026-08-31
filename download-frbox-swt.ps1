# 从 FRBox 网盘下载 SWT 外发文件到桌面
# 文件: X6896-16.3.0.062(OP001PF001AZ)TMP260827182047_SU.zip (~10.6 GB)

$ErrorActionPreference = 'Stop'

$ShareId   = 'HZ4P7WAh1EF'
$SharePwd  = 'p0xLyG'
$ApiBase   = 'https://fra315.api.aliyunpds.com'
$DestDir   = Join-Path $env:USERPROFILE 'Desktop\★★乱糟糟文档★★'
$FileName  = 'X6896-16.3.0.062(OP001PF001AZ)TMP260827182047_SU.zip'
$DestPath  = Join-Path $DestDir $FileName

function Get-ShareToken {
    $body = @{ share_id = $ShareId; share_pwd = $SharePwd } | ConvertTo-Json
    $resp = Invoke-RestMethod -Method Post -Uri "$ApiBase/v2/share_link/get_share_token" `
        -ContentType 'application/json' -Body $body
    return $resp.share_token
}

function Invoke-PdsApi {
    param(
        [string]$Path,
        [hashtable]$Body,
        [string]$Token
    )
    $headers = @{}
    if ($Token) { $headers['x-share-token'] = $Token }
    return Invoke-RestMethod -Method Post -Uri "$ApiBase/$Path" `
        -ContentType 'application/json' -Headers $headers -Body ($Body | ConvertTo-Json)
}

function Find-FileId {
    param([string]$Token)
    $root = Invoke-PdsApi -Path 'v2/file/list' -Body @{
        share_id = $ShareId; parent_file_id = 'root'
    } -Token $Token

    foreach ($item in $root.items) {
        if ($item.type -eq 'folder') {
            $sub = Invoke-PdsApi -Path 'v2/file/list' -Body @{
                share_id = $ShareId; parent_file_id = $item.file_id
            } -Token $Token
            foreach ($f in $sub.items) {
                if ($f.name -eq $FileName) { return $f.file_id }
            }
        } elseif ($item.name -eq $FileName) {
            return $item.file_id
        }
    }
    throw "未在分享中找到文件: $FileName"
}

function Download-WithResume {
    param(
        [string]$Url,
        [string]$Token,
        [string]$OutPath,
        [long]$TotalSize
    )
    $existingSize = 0L
    if (Test-Path $OutPath) {
        $existingSize = (Get-Item $OutPath).Length
        if ($existingSize -eq $TotalSize) { return $true }
        if ($existingSize -gt $TotalSize) {
            Remove-Item $OutPath -Force
            $existingSize = 0
        }
    }

    $request = [System.Net.HttpWebRequest]::Create($Url)
    $request.Headers.Add('x-share-token', $Token)
    if ($existingSize -gt 0) {
        $request.AddRange($existingSize)
        $mode = [System.IO.FileMode]::Append
        Write-Host "  从 $([math]::Round($existingSize / 1MB, 1)) MB 处续传..."
    } else {
        $mode = [System.IO.FileMode]::Create
    }

    $response = $request.GetResponse()
    $responseStream = $response.GetResponseStream()
    $fileStream = [System.IO.File]::Open($OutPath, $mode, [System.IO.FileAccess]::Write)
    $buffer = New-Object byte[] 4194304
    $downloaded = $existingSize
    $lastReport = [DateTime]::Now

    try {
        while (($read = $responseStream.Read($buffer, 0, $buffer.Length)) -gt 0) {
            $fileStream.Write($buffer, 0, $read)
            $downloaded += $read
            $now = [DateTime]::Now
            if (($now - $lastReport).TotalSeconds -ge 2) {
                $pct = [math]::Round($downloaded / $TotalSize * 100, 1)
                $mb = [math]::Round($downloaded / 1MB, 1)
                $totalMb = [math]::Round($TotalSize / 1MB, 1)
                Write-Host "`r  进度: $pct% ($mb / $totalMb MB)   " -NoNewline
                $lastReport = $now
            }
        }
    } finally {
        $fileStream.Close()
        $responseStream.Close()
        $response.Close()
    }

    return ((Get-Item $OutPath).Length -eq $TotalSize)
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " FRBox SWT 文件下载" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if (-not (Test-Path $DestDir)) {
    New-Item -ItemType Directory -Path $DestDir -Force | Out-Null
    Write-Host "已创建目录: $DestDir"
}

Write-Host "[1/3] 获取分享令牌..."
$token = Get-ShareToken

Write-Host "[2/3] 查找文件..."
$fileId = Find-FileId -Token $token
$dlInfo = Invoke-PdsApi -Path 'v2/file/get_download_url' -Body @{
    share_id = $ShareId; file_id = $fileId
} -Token $token
$totalSize = [long]$dlInfo.size
Write-Host "  文件: $FileName"
Write-Host "  大小: $([math]::Round($totalSize / 1GB, 2)) GB"

Write-Host "[3/3] 下载到: $DestPath"
Write-Host "  (支持断点续传，中断后重新运行即可继续)"
Write-Host ""

$ok = Download-WithResume -Url $dlInfo.url -Token $token -OutPath $DestPath -TotalSize $totalSize

Write-Host ""
if ($ok) {
    Write-Host "下载完成!" -ForegroundColor Green
    Write-Host "保存位置: $DestPath"
} else {
    Write-Host "下载未完成，请重新运行脚本续传。" -ForegroundColor Yellow
}
