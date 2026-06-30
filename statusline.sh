#!/bin/sh
CLAUDEDIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
CACHE="$CLAUDEDIR/.weather-cache"
[ -f "$CACHE" ] && printf '\033[38;5;188m%s\033[0m' "$(head -1 "$CACHE")"
