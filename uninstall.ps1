<#
.SYNOPSIS
  卸载 Claude Code 天气状态行插件
#>
$ErrorActionPreference = 'Stop'
$ClaudeDir = if ($env:CLAUDE_CONFIG_DIR) { $env:CLAUDE_CONFIG_DIR } else { Join-Path $HOME ".claude" }

Write-Host "[1/3] 删除 hook 脚本" -ForegroundColor Cyan
Remove-Item (Join-Path $ClaudeDir "hooks" "session-start.py") -Force -ErrorAction SilentlyContinue
Remove-Item (Join-Path $ClaudeDir "hooks" "statusline.ps1") -Force -ErrorAction SilentlyContinue
Remove-Item (Join-Path $ClaudeDir ".weather-cache") -Force -ErrorAction SilentlyContinue

Write-Host "[2/3] 删除定时任务" -ForegroundColor Cyan
schtasks /delete /tn "ClaudeWeather" /f 2>$null

Write-Host "[3/3] 恢复 settings.json" -ForegroundColor Cyan
$SettingsFile = Join-Path $ClaudeDir "settings.json"
$Backups = Get-ChildItem "${SettingsFile}.backup-*" | Sort-Object LastWriteTime -Descending
if ($Backups) {
    Copy-Item $Backups[0].FullName $SettingsFile -Force
    Write-Host "  已从 $($Backups[0].Name) 恢复" -ForegroundColor DarkGray
} else {
    Write-Host "  未找到备份，需手动移除 settings.json 中的 SessionStart/statusLine 配置" -ForegroundColor Yellow
}

Write-Host "`n✅ 卸载完成" -ForegroundColor Green
