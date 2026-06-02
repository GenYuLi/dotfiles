#!/usr/bin/env bash
# Claude Code Notification hook → tmux popup + clickable desktop toast.
# One script, platform-dispatched by uname: the shared core (payload,
# title, tmux popup + 3-layer restore, terminal-PID detection) is
# identical everywhere; only the desktop-notify tool and the
# window-raise mechanism differ per OS.
#
#   Linux/KDE : notify-send -A  +  KWin scripting raise-by-PID      [tested]
#   macOS     : terminal-notifier -execute + System Events raise    [tested]
#
# Wired in ~/.claude/settings.json under hooks.Notification.
# Icon override: ~/.claude/assets/claude.png (else Freedesktop `starred`).

set -u

SELF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
ICON_PATH="$HOME/.claude/assets/claude.png"

# Shared notification primitives (KWin runner, macOS frontmost/toast).
. "$(dirname "$SELF")/notify-lib.sh"

# ── Terminal emulator regex (covers Linux + macOS terminals) ──
TERM_RE='lacritty|ghostty|kitty|foot|wezterm|konsole|gnome-terminal|xterm|iTerm|Terminal'

# Find the terminal-emulator PID by walking up from processes on a tty.
# Linux tty = /dev/pts/N, macOS tty = /dev/ttysNNN; `ps -o … -t <tty>`
# works on both (GNU + BSD ps).
term_pid_from_tty() {
  local tty="${1#/dev/}" p cur comm
  [ -n "$tty" ] || return 1
  for p in $(ps -o pid= -t "$tty" 2>/dev/null); do
    cur=$p
    while [ "${cur:-0}" -gt 1 ] 2>/dev/null; do
      comm=$(ps -o comm= -p "$cur" 2>/dev/null)
      if printf '%s' "$comm" | grep -qiE "$TERM_RE"; then
        printf '%s\n' "$cur"; return 0
      fi
      cur=$(ps -o ppid= -p "$cur" 2>/dev/null | tr -d ' ')
    done
  done
  return 1
}

# ── Shared: restore tmux focus across all three layers ──
# select-pane alone won't change the active window, so a toast raised
# from window 2 lands wrong if you're viewing another window — hence
# select-window (pane id resolves to its containing window) too.
tmux_restore() {
  local sess="$1" pane="$2" client="${3:-}"
  [ -n "$pane" ] || return 0
  if [ -n "$sess" ]; then
    # Explicit -c <client> when known: the macOS click handler runs
    # detached (no $TMUX to identify the current client). On Linux the
    # handler runs inline so $client is empty and tmux resolves the
    # client from the inherited $TMUX.
    if [ -n "$client" ]; then
      tmux switch-client -c "$client" -t "$sess" 2>/dev/null
    else
      tmux switch-client -t "$sess" 2>/dev/null
    fi
  fi
  tmux select-window -t "$pane" 2>/dev/null
  tmux select-pane -t "$pane" 2>/dev/null
}

# ── Linux/KDE: raise a window by PID via KWin scripting ──
# KDE Wayland blocks wmctrl/xdotool/kdotool; the compositor's own
# scripting API is the only privileged focus-by-PID path. Probes for
# KWin first and no-ops on GNOME/sway/bare X.
raise_pid_kwin() {
  local pid="$1"
  nlib_kwin_run "$(cat <<EOF
const target = $pid;
const wins = workspace.windowList ? workspace.windowList() : workspace.clientList();
for (const w of wins) { if (w.pid === target) { workspace.activeWindow = w; } }
EOF
)"
}

# ── macOS: raise the terminal window. Prefer PID → System Events
#    set-frontmost: robust, and works even though the nix-store
#    Alacritty.app is not in /Applications (so name resolution via
#    LaunchServices can fail). Fall back to activate-by-name when no PID
#    was resolved; the name defaults to Alacritty, override with
#    $CC_NOTIFY_MAC_APP. ──
raise_macos() {
  local pid="$1" app="${2:-${CC_NOTIFY_MAC_APP:-Alacritty}}"
  if [ -n "$pid" ] && osascript -e \
    "tell application \"System Events\" to set frontmost of (first process whose unix id is $pid) to true" \
    >/dev/null 2>&1; then
    return 0
  fi
  case "$app" in
    Apple_Terminal) app="Terminal" ;;
    *.app) app="${app%.app}" ;;
  esac
  osascript -e "tell application \"$app\" to activate" >/dev/null 2>&1 || true
}

# ── --jump subcommand: invoked by macOS terminal-notifier -execute on
#    click (Linux does the equivalent inline, see notify_linux). The
#    click handler is relaunched by LaunchServices with a minimal PATH
#    and no $TMUX, so notify_macos bakes the full PATH into the -execute
#    string (otherwise bare `tmux` is not found) and passes the client
#    tty explicitly. Args:
#    --jump <session> <pane_id> <term_pid> <client_tty> ──
if [ "${1:-}" = "--jump" ]; then
  tmux_restore "${2:-}" "${3:-}" "${5:-}"
  [ "$OSTYPE" != "${OSTYPE#darwin}" ] && raise_macos "${4:-}"
  exit 0
fi

# ════════════════ shared setup ════════════════
payload="$(cat -)"
event="$(printf '%s' "$payload" | jq -r '.hook_event_name // ""' 2>/dev/null)"
msg="$(printf '%s' "$payload" | jq -r '.message // ""' 2>/dev/null)"
# Stop fires every turn-end and carries no message; give it its own text
# and route it through the focus-guarded path below (Notification is
# already focus-suppressed by CC itself, so it stays clickable/precise).
if [ -z "$msg" ]; then
  [ "$event" = "Stop" ] && msg="✅ Claude 講完一輪了" || msg="Claude Code needs your attention"
fi

icon="$ICON_PATH"
[ -f "$icon" ] || icon="starred"

title="Claude"
saved_pane="${TMUX_PANE:-}"
saved_sess=""
term_pid=""
term_app="${TERM_PROGRAM:-}"
client_tty=""

if [ -n "${TMUX:-}" ] && [ -n "$saved_pane" ]; then
  saved_sess="$(tmux display-message -p -t "$saved_pane" '#{session_name}' 2>/dev/null || true)"
  pane_loc="$(tmux display-message -p -t "$saved_pane" '#{session_name}:#{window_index}.#{pane_index}' 2>/dev/null || true)"
  cwd_base="$(tmux display-message -p -t "$saved_pane" '#{b:pane_current_path}' 2>/dev/null || true)"
  [ -n "$pane_loc" ] && title="Claude · $pane_loc"
  [ -n "$cwd_base" ] && title="$title · $cwd_base"
  tmux display-message "🔔 $title: $msg" 2>/dev/null
  client_tty="$(tmux list-clients -t "$saved_sess" -F '#{client_tty}' 2>/dev/null | head -1)"
  [ -n "$client_tty" ] && term_pid="$(term_pid_from_tty "$client_tty" || true)"
else
  cwd_base="$(basename "${PWD:-/}")"
  [ -n "$term_app" ] && title="$title · $term_app"
  [ -n "$cwd_base" ] && [ "$cwd_base" != "/" ] && title="$title · $cwd_base"
  term_pid="$(term_pid_from_tty "$(tty 2>/dev/null)" || true)"
fi

# ════════════════ Linux backend (tested) ════════════════
# notify-send -A implies --wait (blocks until click/timeout) → detach to
# background so the hook returns immediately. On click: tmux restore +
# KWin raise-by-PID, done inline (vars are in scope here).
notify_linux() {
  (
    action="$(timeout 120 notify-send -u normal -i "$icon" \
      -A 'default=Jump here' \
      "$title" "$msg" 2>/dev/null)"
    if [ "$action" = "default" ]; then
      tmux_restore "$saved_sess" "$saved_pane"
      [ -n "$term_pid" ] && raise_pid_kwin "$term_pid"
    fi
  ) >/dev/null 2>&1 </dev/null &
  disown 2>/dev/null || true
}

# ── Linux/KDE focus-guarded notify (for Stop) ──
# Stop fires on every turn-end, so stay quiet only when you're actually
# LOOKING AT the CC pane — pane-precise, not just "some Alacritty is
# focused". Two signals are combined: the shell checks (tmux) whether
# saved_pane is the currently-displayed pane; KWin checks whether the
# focused OS window is Alacritty. Quiet only when BOTH hold. So a Stop
# while you're on another tmux window/session/problem — or in Chrome —
# still toasts. The shell passes its tmux verdict into the KWin script as
# a 0/1 literal; the JS ANDs it with its own focus check.
# Click → desktop-entry hint raises the terminal (best-effort, not the
# precise pane — that needs the shell-side notify-send -A path which
# can't be focus-guarded).
notify_linux_guarded() {
  # viewing=1 → saved_pane is the pane currently on screen. Default 1 when
  # not in tmux, so the guard degrades to plain window-level focus.
  local viewing=1
  if [ -n "$saved_pane" ]; then
    viewing=0
    local v
    v="$(tmux display-message -p -t "$saved_pane" '#{?pane_active,1,0}#{?window_active,1,0}#{?session_attached,1,0}' 2>/dev/null)"
    [ "$v" = "111" ] && viewing=1
  fi
  local gicon="$icon" entry="${CC_NOTIFY_DESKTOP_ENTRY:-Alacritty}"
  # JSON-encode every interpolated value: this KWin script runs in a
  # privileged context (callDBus to any service), so a value containing a
  # double-quote or JS (e.g. a crafted cwd basename in $title) could break
  # out of the string literal and inject code. `jq -Rs .` emits a safe,
  # fully-escaped JSON string literal (also valid JS); embed it WITHOUT
  # surrounding quotes since jq supplies them.
  local gicon_j title_j msg_j entry_j
  gicon_j="$(printf '%s' "$gicon" | jq -Rs .)"
  title_j="$(printf '%s' "$title" | jq -Rs .)"
  msg_j="$(printf '%s' "$msg" | jq -Rs .)"
  entry_j="$(printf '%s' "$entry" | jq -Rs .)"
  nlib_kwin_run "$(cat <<EOF
const w = workspace.activeWindow || workspace.activeClient;
const cls = w ? (w.resourceClass || "") : "";
const focusedAla = /alacritty/i.test(cls);
const viewing = $viewing;
// Quiet only when you're focused on Alacritty AND it's showing the CC pane.
if (!(focusedAla && viewing)) {
  callDBus("org.freedesktop.Notifications", "/org/freedesktop/Notifications",
    "org.freedesktop.Notifications", "Notify",
    "Claude Code", 0, $gicon_j,
    $title_j, $msg_j,
    ["default", "Jump"], {"desktop-entry": $entry_j}, 8000);
}
EOF
)"
}

# ════════════════ macOS backend (tested on macOS 26) ════════════════
# terminal-notifier -execute runs a shell command on click; we re-invoke
# this script in --jump mode (it can't see these vars otherwise). Falls
# back to osascript display-notification (no click action) when
# terminal-notifier isn't installed.
notify_macos() {
  # Bake the full PATH and client tty into the click action: the handler is
  # relaunched by LaunchServices with a minimal PATH and no $TMUX, so bare
  # `tmux` would not be found and switch-client would have no client to act
  # on. nlib_toast_macos handles the sprite (-contentImage) and reaps stale
  # click-waiters before posting.
  local execute
  execute="$(printf 'PATH=%q %q --jump %q %q %q %q' "$PATH" "$SELF" "$saved_sess" "$saved_pane" "$term_pid" "$client_tty")"
  nlib_toast_macos "$title" "$msg" "$ICON_PATH" "$execute"
}

# ── macOS focus-guarded notify (for Stop) ──
# Stop fires on every turn-end, so stay quiet only when you're actually
# LOOKING AT the CC pane — pane-precise, mirroring notify_linux_guarded.
# Two signals are ANDed: the frontmost GUI app is Alacritty (System
# Events), AND (in tmux) saved_pane is the on-screen active pane. Quiet
# only when BOTH hold; otherwise toast (still clickable). viewing
# defaults to 1 when not in tmux, degrading to plain window-level focus.
notify_macos_guarded() {
  local viewing=1
  if [ -n "$saved_pane" ]; then
    viewing=0
    local v
    v="$(tmux display-message -p -t "$saved_pane" '#{?pane_active,1,0}#{?window_active,1,0}#{?session_attached,1,0}' 2>/dev/null)"
    [ "$v" = "111" ] && viewing=1
  fi
  local front; front="$(nlib_frontmost_app)"
  local focused_term=0
  case "$front" in
    [Aa]lacritty) focused_term=1 ;;
  esac
  if [ "$focused_term" = 1 ] && [ "$viewing" = 1 ]; then
    return 0
  fi
  notify_macos
}

# ════════════════ SSH backend ════════════════
# Over SSH the hook runs on the REMOTE: notify-send / terminal-notifier /
# KWin all target the remote (headless / not where you're looking). The
# only things that reach the terminal you're attached from are bytes on
# the tty: the tmux popup (already fired above, carries the message) and
# escape sequences written to the client tty, which route back over SSH
# to the local terminal. Emit both OSC 9 (rich notification — honored by
# ghostty/kitty/iTerm/WezTerm, silently ignored by Alacritty) and BEL
# (urgency hint — Alacritty flashes the taskbar). No window raise: the
# remote can't reach the local compositor.
is_ssh() { [ -n "${SSH_CONNECTION:-}" ] || [ -n "${SSH_TTY:-}" ]; }

notify_ssh() {
  local tty="${client_tty:-${SSH_TTY:-}}"
  [ -n "$tty" ] || return 0
  if [ -n "${TMUX:-}" ]; then
    # tmux passthrough: \ePtmux; <ESC-doubled inner> \e\\
    printf '\ePtmux;\033\033]9;%s\007\033\\' "$msg" > "$tty" 2>/dev/null || true
  else
    printf '\033]9;%s\007' "$msg" > "$tty" 2>/dev/null || true
  fi
  printf '\a' > "$tty" 2>/dev/null || true
}

if is_ssh; then
  # SSH Stop is focus-guarded downstream: the BEL reaches the local
  # Alacritty, whose bell.command runs the focus-guarded bell-notify.
  notify_ssh
else
  case "$(uname)" in
    Darwin) if [ "$event" = "Stop" ]; then notify_macos_guarded; else notify_macos; fi ;;
    *)      if [ "$event" = "Stop" ]; then notify_linux_guarded; else notify_linux; fi ;;
  esac
fi

exit 0
