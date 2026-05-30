#!/usr/bin/env bash
# Claude Code Notification hook → tmux popup + libnotify desktop toast.
# Wired in ~/.claude/settings.json under hooks.Notification. Fires when
# CC wants user attention (permission prompt, idle nudge, etc.) — not
# on every assistant turn, so it won't spam.
#
# Icon: drop a PNG at ~/.claude/assets/claude.png to override the
# Freedesktop fallback (`starred` — closest to Claude's orange sparkle).

set -u

payload="$(cat -)"
msg="$(printf '%s' "$payload" | jq -r '.message // "Claude Code needs your attention"' 2>/dev/null)"
[ -z "$msg" ] && msg="Claude Code needs your attention"

icon="$HOME/.claude/assets/claude.png"
[ -f "$icon" ] || icon="starred"

# tmux: only when CC is launched inside a tmux client.
[ -n "${TMUX:-}" ] && tmux display-message "🔔 Claude: $msg" 2>/dev/null

# Desktop: tolerate missing DISPLAY / no dbus session — never block CC.
notify-send -u normal -i "$icon" "Claude Code" "$msg" 2>/dev/null || true

exit 0
