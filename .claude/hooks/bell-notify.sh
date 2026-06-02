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
#   macOS     : osascript frontmost check + terminal-notifier toast
#               (osascript display-notification fallback)
#               [toast path tested; full remote-BEL→local SSH chain not
#                yet e2e-verified on macOS]

set -u

# Shared notification primitives (KWin runner, macOS frontmost/toast, PATH).
. "$(dirname "${BASH_SOURCE[0]}")/notify-lib.sh"

# bell.command launches this with launchd's minimal PATH (no nix profile),
# so terminal-notifier / notify-send wouldn't be found — fix it up.
nlib_setup_path

ICON="$HOME/.claude/assets/claude.png"

# ── Linux/KDE: focus check + notify inside one KWin script ──
# A plain shell can't read the active window on KDE Wayland
# (queryWindowInfo is interactive), but KWin's privileged JS context can,
# and can callDBus the freedesktop Notify too. No-ops without gdbus/KWin.
bell_linux() {
  local icon="$ICON"; [ -f "$icon" ] || icon="dialog-information"
  # JSON-encode the icon path before embedding into the privileged KWin
  # script (jq -Rs . emits a safe JS string literal; no surrounding quotes).
  local icon_j; icon_j="$(printf '%s' "$icon" | jq -Rs .)"
  nlib_kwin_run "$(cat <<EOF
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
)"
}

# ── macOS: frontmost-app check + toast. System Events reports the
# frontmost app; skip the toast when it's a terminal (you're looking at
# it). Prefer terminal-notifier for the Claude icon; fall back to
# osascript. No click action — matches the bell's "just nudge me" role
# and the Linux bell's empty actions array. ──
bell_macos() {
  # Skip the toast when a terminal is frontmost (you're already looking).
  local front; front="$(nlib_frontmost_app)"
  case "$front" in
    [Aa]lacritty|iTerm*|[Gg]hostty|kitty|WezTerm|Terminal) return 0 ;;
  esac
  # No click action — a plain nudge, matching the Linux bell's empty actions.
  nlib_toast_macos "Claude Code" "needs your attention" "$ICON"
}

case "$(uname)" in
  Darwin) bell_macos ;;
  *)      bell_linux ;;
esac

exit 0
