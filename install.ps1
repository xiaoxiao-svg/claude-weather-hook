<#
.SYNOPSIS
  安装 Claude Code 天气状态行插件
.DESCRIPTION
  - 将 weather.py 部署为 SessionStart hook
  - 注册 statusline.ps1 为状态行命令
  - 创建 Windows 定时任务（9-21点每3小时刷新缓存）
  - 备份已有 settings.json
#>

$ErrorActionPreference = 'Stop'

# --- 路径 ---
$SrcDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ClaudeDir = if ($env:CLAUDE_CONFIG_DIR) { $env:CLAUDE_CONFIG_DIR } else { Join-Path $HOME ".claude" }
$HookDir = Join-Path $ClaudeDir "hooks"
$SettingsFile = Join-Path $ClaudeDir "settings.json"

# --- 1. 部署脚本 ---
Write-Host "[1/4] 部署 hook 脚本 → $HookDir" -ForegroundColor Cyan
New-Item -ItemType Directory -Force -Path $HookDir | Out-Null
Copy-Item (Join-Path $SrcDir "weather.py") (Join-Path $HookDir "session-start.py") -Force
Copy-Item (Join-Path $SrcDir "statusline.ps1") (Join-Path $HookDir "statusline.ps1") -Force

# --- 2. 配置 settings.json ---
Write-Host "[2/4] 配置 settings.json" -ForegroundColor Cyan
$Settings = @{}
if (Test-Path $SettingsFile) {
    $Content = Get-Content $SettingsFile -Raw -Encoding UTF8
    if ($Content) { $Settings = $Content | ConvertFrom-Json -AsHashtable }
    # 备份
    $Backup = "${SettingsFile}.backup-$(Get-Date -Format 'yyyyMMddHHmmss')"
    Copy-Item $SettingsFile $Backup
    Write-Host "  已备份 → $Backup" -ForegroundColor DarkGray
}

# SessionStart hook
if (-not $Settings.Contains('hooks')) { $Settings['hooks'] = @{} }
if (-not $Settings['hooks'].Contains('SessionStart')) {
    $Settings['hooks']['SessionStart'] = @(@{
        hooks = @(@{
            type = 'command'
            command = "python `"$(Join-Path $HookDir 'session-start.py')`""
            timeout = 15
        })
    })
} else {
    Write-Host "  SessionStart hook 已存在，跳过（需手动添加）" -ForegroundColor Yellow
}

# statusLine
$Ps1Path = Join-Path $HookDir 'statusline.ps1'
$StatusCmd = "powershell -ExecutionPolicy Bypass -File `"$Ps1Path`""
if (-not $Settings.Contains('statusLine')) {
    $Settings['statusLine'] = @{ type = 'command'; command = $StatusCmd }
} else {
    Write-Host "  statusLine 已存在，跳过（需手动添加）" -ForegroundColor Yellow
}

# 写回（保留已有字段）
$Settings | ConvertTo-Json -Depth 10 | Set-Content $SettingsFile -Encoding UTF8
Write-Host "  → $SettingsFile" -ForegroundColor DarkGray

# --- 3. 定时任务 ---
Write-Host "[3/4] 创建 Windows 定时任务" -ForegroundColor Cyan
$PythonPath = (Get-Command python).Source
$TaskName = "ClaudeWeather"
$TaskCmd = "`"$PythonPath`" `"$(Join-Path $HookDir 'session-start.py')`""

# 检查是否已存在
$Existing = schtasks /query /tn $TaskName 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "  定时任务 '$TaskName' 已存在，跳过（如需重建请先手动删除）" -ForegroundColor Yellow
} else {
    $Arg = "/create /tn `"$TaskName`" /tr `"$TaskCmd`" /sc daily /st 09:00 /du 12:00 /ri 180 /f"
    $Result = schtasks $Arg 2>&1
    Write-Host "  $Result" -ForegroundColor DarkGray
}

# --- 4. 验证 ---
Write-Host "[4/4] 验证安装" -ForegroundColor Cyan
python (Join-Path $HookDir 'session-start.py') 2>&1 | Out-Null
$CacheFile = Join-Path $ClaudeDir ".weather-cache"
if (Test-Path $CacheFile) {
    $Content = Get-Content $CacheFile -Encoding UTF8 -First 1
    Write-Host "  ✓ 缓存写入成功" -ForegroundColor Green
    Write-Host "  → $Content" -ForegroundColor DarkGray
} else {
    Write-Host "  ✗ 缓存未生成，请检查 Python 环境" -ForegroundColor Red
    exit 1
}

Write-Host "`n✅ 安装完成！重启 Claude Code 后生效。" -ForegroundColor Green
Write-Host "  如需卸载：运行 uninstall.ps1" -ForegroundColor DarkGray
