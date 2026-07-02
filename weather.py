# -*- coding: utf-8 -*-
"""
Claude Code Weather Hook
一个会话问候 + 状态行天气脚本。每次运行获取天气、写缓存、打印问候。
可挂 SessionStart hook + 定时任务全天刷新。
"""
import json
import os
import random
import re
import sys
import urllib.request
from datetime import datetime


def print_utf8(*args, sep=' ', end='\n'):
    out = sep.join(str(arg) for arg in args) + end
    sys.stdout.buffer.write(out.encode('utf-8'))


def fetch(url, timeout=8):
    try:
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'})
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            return resp.read()
    except Exception:
        return None


# ---------- 天气 ---------- 可选city，不依靠IP获取城市天气，?lang=zh&city=XX
raw = fetch('https://uapis.cn/api/v1/misc/weather?lang=zh')
weather_data = json.loads(raw.decode('utf-8')) if raw else {}

city = weather_data.get('city', '') or 'Unknown'
temp = weather_data.get('temperature')
humid = weather_data.get('humidity')
weather_text = weather_data.get('weather', '')
wind_dir = weather_data.get('wind_direction', '')
wind_pow = str(weather_data.get('wind_power', ''))

wse = None
if wind_pow:
    m = re.search(r'(\d+)', wind_pow)
    wse = int(m.group(1)) if m else None

wind_str = ''
if wse is not None:
    wind_str = f'{wind_dir}{["无风", "1级", "2级", "3级", "4级", "5级", "6级", "7级", "8级", "9级", "10级", "11级", "12级"][min(12, max(0, wse))]}'

weather_desc = ''
if weather_text:
    weather_desc = f'{city} {weather_text}'
    if wind_str: weather_desc += f' {wind_str}'
    if humid is not None: weather_desc += f' 湿度：{humid}%'

umbrella = '☂️ 带伞' if '雨' in weather_text else '☀️ 不下雨'

t_advice = ''
if temp is not None:
    for th, msg in [(38, '🔥 极端高温'), (33, '🥵 热炸了'), (28, '🌤️ 有点热'),
                    (22, '🌿 舒适'), (16, '🍂 微凉'), (8, '🧥 冷')]:
        if temp >= th: t_advice = msg; break
    if temp < 8: t_advice = '🥶 很冷'


# ---------- 问候 ----------
h = datetime.now().hour
if h < 5: greet = '🌙 这么晚还没睡？'
elif h < 7: greet = '🌅 清晨好！'
elif h < 9: greet = '☀️ 早上好！'
elif h < 12: greet = '⛅ 上午好！'
elif h < 14: greet = '🌤️ 中午好！'
elif h < 17: greet = '⛅ 下午好！'
elif h < 19: greet = '🌆 傍晚好！'
else: greet = '🌃 晚上好！'


# ---------- 缓存（供状态行读取） ----------
quotes = ['今天改的 bug 都是昨天挖的坑', '代码可以重构，人生不能重来',
          '能用 console.log 解决的 bug 都是好 bug', 'Talk is cheap, show me the code']

# 只存天气+建议——问候语和每日一言由 PS1 脚本动态计算
cache_parts = []
if weather_desc:
    cache_parts.append(weather_desc)
else:
    cache_parts.append(f'📍 {city}')
cache_parts.append(umbrella)
if t_advice: cache_parts.append(t_advice)

claude_dir = os.environ.get('CLAUDE_CONFIG_DIR') or os.path.join(os.path.expanduser('~'), '.claude')
os.makedirs(claude_dir, exist_ok=True)
with open(os.path.join(claude_dir, '.weather-cache'), 'w', encoding='utf-8-sig') as f:
    f.write(' '.join(cache_parts))


# ---------- 问候输出 ----------
if weather_desc:
    print_utf8(f'\n✨ Claude Code {greet}')
    print_utf8(f'   {weather_desc}')
    print_utf8(f'{umbrella} {t_advice}')
    print_utf8(f'💬 {random.choice(quotes)}\n')
else:
    print_utf8(f'\n✨ Claude Code {greet}')
    print_utf8(f'📍 {city}')
    print_utf8(f'💬 {random.choice(quotes)}\n')
