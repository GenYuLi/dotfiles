#!/usr/bin/env bash
# Claude Code Notification hook → tmux popup + clickable libnotify toast.
#
# Title encodes which CC this is (tmux session:win.pane + cwd, or
# terminal + cwd when bare). Clicking the desktop toast jumps to it:
#   - tmux state:  switch-client + select-pane (compositor-independent)
#   - window raise: KWin scripting activates the terminal by PID
#                   (KDE Wayland blocks wmctrl/xdotool; the compositor's
#                    own scripting API is the only privileged path)
#
# Wired in ~/.claude/settings.json under hooks.Notification.
# Icon override: ~/.claude/assets/claude.png (else Freedesktop `starred`).

set -u

# ── Resolve the terminal-emulator PID so the compositor can raise it ──
# Inside tmux the pane runs under the (daemonized) tmux server, so a
# getppid() walk never reaches the terminal. Go via the client tty
# instead: find the tty the session is attached to, then walk up from
# the processes on that tty until a known terminal emulator turns up.
TERM_RE='lacritty|ghostty|kitty|foot|wezterm|konsole|gnome-terminal|xterm'

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

# Raise a window owned by $1 via KWin scripting (KDE Wayland). No-op /
# silent fail anywhere else, so this stays safe on GNOME, sway, bare X.
raise_pid_kwin() {
  local pid="$1"
  command -v gdbus >/dev/null 2>&1 || return 0
  gdbus call --session --dest org.kde.KWin --object-path /Scripting \
    --method org.kde.kwin.Scripting.loadScript / >/dev/null 2>&1 || return 0
  local js; js="$(mktemp /tmp/cc-kwin-XXXXXX.js)" || return 0
  cat > "$js" <<EOF
const target = $pid;
const wins = workspace.windowList ? workspace.windowList() : workspace.clientList();
for (const w of wins) { if (w.pid === target) { workspace.activeWindow = w; } }
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

payload="$(cat -)"
msg="$(printf '%s' "$payload" | jq -r '.message // "Claude Code needs your attention"' 2>/dev/null)"
[ -z "$msg" ] && msg="Claude Code needs your attention"

icon="$HOME/.claude/assets/claude.png"
[ -f "$icon" ] || icon="starred"

title="Claude"
saved_pane="${TMUX_PANE:-}"
saved_sess=""
term_pid=""

if [ -n "${TMUX:-}" ] && [ -n "$saved_pane" ]; then
  saved_sess="$(tmux display-message -p -t "$saved_pane" '#{session_name}' 2>/dev/null || true)"
  pane_loc="$(tmux display-message -p -t "$saved_pane" '#{session_name}:#{window_index}.#{pane_index}' 2>/dev/null || true)"
  cwd_base="$(tmux display-message -p -t "$saved_pane" '#{b:pane_current_path}' 2>/dev/null || true)"
  [ -n "$pane_loc" ] && title="Claude · $pane_loc"
  [ -n "$cwd_base" ] && title="$title · $cwd_base"
  tmux display-message "🔔 $title: $msg" 2>/dev/null
  # Terminal PID via the tty the session's client is attached to.
  client_tty="$(tmux list-clients -t "$saved_sess" -F '#{client_tty}' 2>/dev/null | head -1)"
  [ -n "$client_tty" ] && term_pid="$(term_pid_from_tty "$client_tty" || true)"
else
  # Bare terminal: identify via env + cwd; PID via process-tree walk
  # (no tmux server in the way here, so getppid from us reaches it).
  term_name="${TERM_PROGRAM:-}"
  cwd_base="$(basename "${PWD:-/}")"
  [ -n "$term_name" ] && title="$title · $term_name"
  [ -n "$cwd_base" ] && [ "$cwd_base" != "/" ] && title="$title · $cwd_base"
  term_pid="$(term_pid_from_tty "$(tty 2>/dev/null)" || true)"
fi

# -A implies --wait (blocks until click/timeout) → detach to background so
# the hook returns immediately. On click: restore tmux state, raise window.
(
  action="$(timeout 120 notify-send -u normal -i "$icon" \
    -A 'default=Jump here' \
    "$title" "$msg" 2>/dev/null)"
  if [ "$action" = "default" ]; then
    if [ -n "$saved_pane" ]; then
      # Three independent layers — switch-client (session), select-window
      # (window; resolves the pane id to its containing window) and
      # select-pane (pane). select-pane alone won't change the active
      # window, so a notification from window 2 lands wrong if you're
      # currently on another window.
      [ -n "$saved_sess" ] && tmux switch-client -t "$saved_sess" 2>/dev/null
      tmux select-window -t "$saved_pane" 2>/dev/null
      tmux select-pane -t "$saved_pane" 2>/dev/null
    fi
    [ -n "$term_pid" ] && raise_pid_kwin "$term_pid"
  fi
) >/dev/null 2>&1 </dev/null &
disown 2>/dev/null || true

exit 0
