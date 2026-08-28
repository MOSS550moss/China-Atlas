# 神州万象 - 一键推送到GitHub并部署Pages
# 使用方法：
# 1. 在 GitHub Settings > Developer settings > Personal access tokens 生成一个 token（勾选 repo 权限）
# 2. 运行此脚本，输入 token
# 3. 脚本会自动推送所有文件并启用 GitHub Pages

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  神州万象 - GitHub 一键推送部署脚本" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 配置
$owner = "MOSS550moss"
$repo = "-"
$branch = "main"
$baseDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# 获取 token
$token = Read-Host "请输入 GitHub Personal Access Token (repo 权限)" -AsSecureString
$tokenPlain = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($token))

if ([string]::IsNullOrWhiteSpace($tokenPlain)) {
    Write-Host "错误：Token 不能为空" -ForegroundColor Red
    exit 1
}

$headers = @{
    "Authorization" = "token $tokenPlain"
    "Accept" = "application/vnd.github.v3+json"
    "User-Agent" = "shenzhou-wanxiang-push"
}

# 验证 token
Write-Host "`n正在验证 GitHub 访问权限..." -ForegroundColor Yellow
try {
    $userResp = Invoke-RestMethod -Uri "https://api.github.com/user" -Headers $headers -Method Get
    Write-Host "验证成功，当前用户: $($userResp.login)" -ForegroundColor Green
} catch {
    Write-Host "验证失败: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# 要推送的文件列表（相对路径）
$files = @(
    "README.md",
    ".gitignore",
    "build_html_ios.py",
    "data_merged.js",
    "神州万象.html",
    "index.html",
    "app.jsx",
    "package.json",
    "package-lock.json",
    "thumbnail.png",
    "all_gallery_items.json",
    "gallery_items.json",
    "routes.json",
    "validate.cjs"
)

# 添加 Python 脚本
$pyFiles = Get-ChildItem -Path $baseDir -Filter "*.py" -File
foreach ($f in $pyFiles) {
    if ($files -notcontains $f.Name) {
        $files += $f.Name
    }
}

# 添加 images 目录下的所有文件
$imageFiles = Get-ChildItem -Path "$baseDir\images" -Recurse -File -ErrorAction SilentlyContinue
foreach ($f in $imageFiles) {
    $relPath = $f.FullName.Substring($baseDir.Length + 1).Replace("\", "/")
    $files += $relPath
}

# 添加 data 目录
$dataFiles = Get-ChildItem -Path "$baseDir\data" -Recurse -File -ErrorAction SilentlyContinue
foreach ($f in $dataFiles) {
    $relPath = $f.FullName.Substring($baseDir.Length + 1).Replace("\", "/")
    $files += $relPath
}

# 添加 components 目录
$compFiles = Get-ChildItem -Path "$baseDir\components" -Recurse -File -ErrorAction SilentlyContinue
foreach ($f in $compFiles) {
    $relPath = $f.FullName.Substring($baseDir.Length + 1).Replace("\", "/")
    $files += $relPath
}

$files = $files | Select-Object -Unique
Write-Host "`n待推送文件数: $($files.Count)" -ForegroundColor Yellow

# 推送文件
$successCount = 0
$failCount = 0

foreach ($relPath in $files) {
    $fullPath = Join-Path $baseDir $relPath
    if (-not (Test-Path $fullPath)) {
        Write-Host "  跳过(不存在): $relPath" -ForegroundColor DarkGray
        continue
    }

    $fileSize = (Get-Item $fullPath).Length
    if ($fileSize -gt 100MB) {
        Write-Host "  跳过(过大>100MB): $relPath ($([math]::Round($fileSize/1MB,2))MB)" -ForegroundColor DarkYellow
        continue
    }

    Write-Host "  推送: $relPath ($([math]::Round($fileSize/1KB,1))KB)..." -NoNewline

    try {
        # 读取文件内容并 base64 编码
        $bytes = [System.IO.File]::ReadAllBytes($fullPath)
        $contentBase64 = [System.Convert]::ToBase64String($bytes)

        # 检查文件是否已存在（获取 SHA）
        $apiPath = [uri]::EscapeDataString($relPath)
        $fileUrl = "https://api.github.com/repos/$owner/$repo/contents/$apiPath`?ref=$branch"

        $sha = $null
        try {
            $existing = Invoke-RestMethod -Uri $fileUrl -Headers $headers -Method Get
            $sha = $existing.sha
        } catch {
            # 文件不存在，新建
        }

        # 构建请求体
        $body = @{
            message = "add: $relPath"
            content = $contentBase64
            branch = $branch
        }
        if ($sha) {
            $body.sha = $sha
            $body.message = "update: $relPath"
        }

        $bodyJson = $body | ConvertTo-Json -Compress

        # 推送文件
        $null = Invoke-RestMethod -Uri "https://api.github.com/repos/$owner/$repo/contents/$apiPath" -Headers $headers -Method Put -Body $bodyJson -ContentType "application/json"

        Write-Host " 完成" -ForegroundColor Green
        $successCount++
    } catch {
        Write-Host " 失败: $($_.Exception.Message)" -ForegroundColor Red
        $failCount++
    }
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  推送完成: 成功 $successCount, 失败 $failCount" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# 启用 GitHub Pages
Write-Host "`n正在启用 GitHub Pages..." -ForegroundColor Yellow
try {
    $pagesBody = @{
        source = @{
            branch = $branch
            path = "/"
        }
    } | ConvertTo-Json -Compress

    $null = Invoke-RestMethod -Uri "https://api.github.com/repos/$owner/$repo/pages" -Headers $headers -Method Post -Body $pagesBody -ContentType "application/json"
    Write-Host "GitHub Pages 已启用！" -ForegroundColor Green
    Write-Host "部署地址: https://$owner.github.io/$repo/神州万象.html" -ForegroundColor Cyan
    Write-Host "（首次部署可能需要 1-2 分钟生效）" -ForegroundColor DarkGray
} catch {
    if ($_.Exception.Message -match "already exists") {
        Write-Host "GitHub Pages 已在运行中" -ForegroundColor Yellow
    } else {
        Write-Host "GitHub Pages 启用失败: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "请手动在仓库 Settings > Pages 中启用，分支选择 main，目录选择 /(root)" -ForegroundColor Yellow
    }
}

Write-Host "`n仓库地址: https://github.com/$owner/$repo" -ForegroundColor Cyan
Write-Host "按任意键退出..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
