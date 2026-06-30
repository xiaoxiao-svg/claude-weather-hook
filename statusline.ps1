$ClaudeDir = if ($env:CLAUDE_CONFIG_DIR) { $env:CLAUDE_CONFIG_DIR } else { Join-Path $HOME ".claude" }
$WeatherFile = Join-Path $ClaudeDir ".weather-cache"
$Weather = Get-Content -Path $WeatherFile -Encoding UTF8 -ErrorAction SilentlyContinue | Select-Object -First 1
if ($Weather) {
    $Esc = [char]27
    $OldEnc = [Console]::OutputEncoding
    [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
    [Console]::Write("${Esc}[38;5;188m${Weather}${Esc}[0m")
    [Console]::OutputEncoding = $OldEnc
}
