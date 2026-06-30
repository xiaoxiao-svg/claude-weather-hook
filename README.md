# Claude Code Weather Hook

Claude Code 会话问候 + 状态行天气。启动时显示天气、每日一言，状态行全天自动刷新。

## 效果

```
✨ Claude Code ⛅ 上午好！
   贵阳市 雾 东风2级 湿度：97%
☀️ 不下雨 🍂 微凉
💬 今天改的 bug 都是昨天挖的坑
```

状态行（底部灰色）：`✨ Claude Code ⛅ 上午好！贵阳市 雾 东风2级 湿度：97% ☀️ 不下雨 🍂 微凉 💬 xxx`

## 安装

### Windows

```powershell
# 默认安装
.\install.ps1

# 或指定 Claude 配置目录
$env:CLAUDE_CONFIG_DIR = "D:\my-claude-config"
.\install.ps1
```

安装步骤：
1. 复制 `weather.py` → `~/.claude/hooks/session-start.py`
2. 注册 SessionStart hook + statusLine 到 `settings.json`
3. 创建 Windows 定时任务 `ClaudeWeather`（9:00/12:00/15:00/18:00/21:00）
4. 运行一次验证缓存写入

### macOS / Linux

```bash
# 手动部署
CLAUDEDIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
mkdir -p "$CLAUDEDIR/hooks"
cp weather.py "$CLAUDEDIR/hooks/session-start.py"
cp statusline.sh "$CLAUDEDIR/hooks/statusline.sh"

# 配置 settings.json（见下方示例）

# 定时刷新（crontab）
crontab -l 2>/dev/null | { cat; echo "0 9,12,15,18,21 * * * python3 $CLAUDEDIR/hooks/session-start.py"; } | crontab -
```

### settings.json 手动配置

```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "python \"C:\\Users\\xxx\\.claude\\hooks\\session-start.py\"",
            "timeout": 15
          }
        ]
      }
    ]
  },
  "statusLine": {
    "type": "command",
    "command": "powershell -ExecutionPolicy Bypass -File \"C:\\Users\\xxx\\.claude\\hooks\\statusline.ps1\""
  }
}
```

## 卸载

```powershell
.\uninstall.ps1
```

## 依赖

- **Python 3**（weather.py 运行环境）
- **PowerShell**（statusline.ps1 状态行输出，仅 Windows）
- **[uapis.cn](https://uapis.cn)** 天气 API（国内服务，无需 API Key，有频率限制）

## 自定义

| 修改 | 文件 | 位置 |
|------|------|------|
| 问候语时间分段 | `weather.py` | `h = datetime.now().hour` 后的 if 链 |
| 每日一言列表 | `weather.py` | `quotes = [...]` |
| 温度体感阈值 | `weather.py` | `[(38, '🔥...'), ...]` |
| 状态行颜色 | `statusline.ps1` | `38;5;188`（ANSI 256 色） |
| 刷新时间 | 定时任务 | `schtasks /change /tn ClaudeWeather ...` |

## 文件结构

```
claude-weather-hook/
├── README.md
├── weather.py          ← 主逻辑：获取天气 + 写缓存 + 问候输出
├── statusline.ps1      ← PowerShell：读取缓存 → ANSI 输出到状态行
├── install.ps1         ← Windows 一键安装
└── uninstall.ps1       ← Windows 卸载
```
