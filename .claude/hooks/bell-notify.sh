#!/usr/bin/env bash
# Alacritty `bell.command` handler — desktop toast only when the terminal
# is NOT the focused window. Runs on the machine you're VIEWING from (the
# local side); over SSH it's triggered by cc-notify.sh's BEL byte routed
# back to your local Alacritty.
#
# Why focus-guarded: Alacritty can't render OSC 9 toasts, so the bell is
# the only local signal. But it fires on every bell (vim/zsh beeps too);
# only notifying when you've looked away keeps it from spamming — when
# Alacritty is focused the tmux popup already shows the message.
#
# Platform-dispatched like cc-notify.sh, because "focus check + notify"
# uses entirely different tooling per OS:
#   Linux/KDE : KWin scripting (reads activeWindow + callDBus Notify)  [tested]
#   macOS     : osascript (frontmost app + display notification)       [UNTESTED]

set -u

ICON="$HOME/.claude/assets/claude.png"

# ── Linux/KDE: focus check + notify inside one KWin script ──
# A plain shell can't read the active window on KDE Wayland
# (queryWindowInfo is interactive), but KWin's privileged JS context can,
# and can callDBus the freedesktop Notify too. No-ops without gdbus/KWin.
bell_linux() {
  command -v gdbus >/dev/null 2>&1 || return 0
  gdbus call --session --dest org.kde.KWin --object-path /Scripting \
    --method org.kde.kwin.Scripting.loadScript / >/dev/null 2>&1 || return 0
  local icon="$ICON"; [ -f "$icon" ] || icon="dialog-information"
  # JSON-encode the icon path before embedding into the privileged KWin
  # script (jq -Rs . emits a safe JS string literal; no surrounding quotes).
  local icon_j; icon_j="$(printf '%s' "$icon" | jq -Rs .)"
  local js; js="$(mktemp /tmp/cc-bell-XXXXXX.js)" || return 0
  cat > "$js" <<EOF
const w = workspace.activeWindow || workspace.activeClient;
const cls = w ? (w.resourceClass || "") : "";
if (!/alacritty/i.test(cls)) {
  callDBus("org.freedesktop.Notifications", "/org/freedesktop/Notifications",
    "org.freedesktop.Notifications", "Notify",
    "Claude Code", 0, $icon_j,
    "Claude Code", "needs your attention",
    [], {}, 5000);
}
EOF
  local ret sid
  ret="$(gdbus call --session --dest org.kde.KWin --object-path /Scripting \
    --method org.kde.kwin.Scripting.loadScript "$js" 2>/dev/null)"
  sid="$(printf '%s' "$ret" | grep -oP '\(\K[0-9]+')"
  if [ -n "$sid" ]; then
    gdbus call --session --dest org.kde.KWin --object-path "/Scripting/Script$sid" \
      --method org.kde.kwin.Script.run >/dev/null 2>&1
    gdbus call --session --dest org.kde.KWin --object-path /Scripting \
      --method org.kde.kwin.Scripting.unloadScript "$sid" >/dev/null 2>&1
  fi
  rm -f "$js"
}

# ── macOS: frontmost-app check + toast. System Events reports the
# frontmost app; skip the toast when it's a terminal (you're looking at
# it). Prefer terminal-notifier for the Claude icon; fall back to
# osascript. No click action — matches the bell's "just nudge me" role
# and the Linux bell's empty actions array. ──
bell_macos() {
  command -v osascript >/dev/null 2>&1 || return 0
  local front
  front="$(osascript -e 'tell application "System Events" to name of first application process whose frontmost is true' 2>/dev/null)"
  case "$front" in
    [Aa]lacritty|iTerm*|[Gg]hostty|kitty|WezTerm|Terminal) return 0 ;;
  esac
  if command -v terminal-notifier >/dev/null 2>&1; then
    # -contentImage, not -appIcon (ignored on recent macOS); sprite on the
    # right, terminal-notifier's own icon stays as the main mark.
    local contentimg=()
    [ -f "$ICON" ] && contentimg=(-contentImage "$ICON")
    terminal-notifier -title "Claude Code" -message "needs your attention" "${contentimg[@]}" \
      >/dev/null 2>&1 &
    disown 2>/dev/null || true
  else
    osascript -e 'display notification "needs your attention" with title "Claude Code"' >/dev/null 2>&1 || true
  fi
}

case "$(uname)" in
  Darwin) bell_macos ;;
  *)      bell_linux ;;
esac

exit 0
