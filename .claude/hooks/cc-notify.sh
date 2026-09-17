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
# Wired in ~/.claude/settings.json under hooks.Notification and hooks.Stop.
# Codex reuses it as `cc-notify.sh --agent codex` for its Stop and
# PermissionRequest hooks (registered by .codex/sync-plugins.sh); Codex parses a
# hook's stdout as a decision, so this script never writes to stdout.
# Icon override: ~/.claude/assets/claude.png (else Freedesktop `starred`).
#
# The agent may live in a tmux pane, in a herdr pane, or in a bare terminal.
# herdr's own toasts are drawn by an attached herdr client, so with nobody
# attached (e.g. the terminal was handed back to tmux) this hook is the only
# thing that can reach the desktop.
#
# Optional remote channel: ~/.config/cc-notify/env with
#   CC_NOTIFY_WEBHOOK_URL=https://hooks.slack.com/services/...
#   CC_NOTIFY_WEBHOOK_EVENTS="Notification PermissionRequest"   # default

set -u

SELF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
ICON_PATH="$HOME/.claude/assets/claude.png"

# Shared notification primitives (KWin runner, macOS frontmost/toast).
. "$(dirname "$SELF")/notify-lib.sh"

# ── Which agent is calling? Claude Code unless told otherwise. ──
AGENT="Claude"
if [ "${1:-}" = "--agent" ]; then
  case "${2:-}" in
    codex | Codex) AGENT="Codex" ;;
    "") ;;
    *) AGENT="$2" ;;
  esac
  shift 2 2>/dev/null || shift $#
fi

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

# ── herdr awareness ──
# herdr exports these into every pane it spawns.
in_herdr() { [ "${HERDR_ENV:-}" = 1 ] && [ -n "${HERDR_PANE_ID:-}" ]; }
herdr_bin() { command -v herdr 2>/dev/null || printf '%s\n' "$HOME/.local/bin/herdr"; }

# PIDs of the terminal-emulator windows that currently show a herdr client.
# `herdr server` has no tty; a client spawned by a gateway (herdr-pwa's
# node-pty) has a tty but no terminal emulator above it, so term_pid_from_tty
# fails and it is ignored: a phone looking at herdr is not you at the desk.
herdr_term_pids() {
  local p args tty t out=""
  for p in $(pgrep -x herdr 2>/dev/null); do
    args="$(ps -o args= -p "$p" 2>/dev/null)"
    case "$args" in *" server"*) continue ;; esac
    tty="$(ps -o tty= -p "$p" 2>/dev/null | tr -d ' ')"
    case "$tty" in "" | "?" | "??") continue ;; esac
    t="$(term_pid_from_tty "/dev/$tty" 2>/dev/null)" || continue
    [ -n "$t" ] && out="$out${out:+ }$t"
  done
  printf '%s\n' "$out"
}

# Is this agent's pane the one herdr has focused?
herdr_pane_focused() {
  "$(herdr_bin)" api snapshot 2>/dev/null |
    jq -e --arg id "$HERDR_PANE_ID" \
      '[.. | objects | select(.pane_id? == $id)][0].focused == true' >/dev/null 2>&1
}

# viewing=1 → the agent's pane is what the user has on screen, so a Stop toast
# would be noise. view_term_pids narrows "on screen" to specific terminal
# windows when known (herdr); empty means "any focused terminal" (tmux/bare).
compute_viewing() {
  viewing=1
  view_term_pids=""
  if [ -n "$saved_pane" ]; then
    viewing=0
    local v
    v="$(tmux display-message -p -t "$saved_pane" '#{?pane_active,1,0}#{?window_active,1,0}#{?session_attached,1,0}' 2>/dev/null)"
    [ "$v" = "111" ] && viewing=1
  elif in_herdr; then
    # Without $TMUX_PANE the old default was viewing=1, i.e. "some terminal is
    # focused" — true even when that terminal shows tmux and nobody has herdr
    # open, which swallowed every turn-finished toast.
    viewing=0
    view_term_pids="$(herdr_term_pids)"
    if [ -n "$view_term_pids" ] && herdr_pane_focused; then
      viewing=1
    fi
  fi
}

# Click on a toast for an agent in herdr: bring herdr to the user.
herdr_jump() {
  local hb pids ctty tpid
  hb="$(herdr_bin)"
  [ -n "${HERDR_TAB_ID:-}" ] && "$hb" tab focus "$HERDR_TAB_ID" >/dev/null 2>&1
  pids="$(herdr_term_pids)"
  if [ -n "$pids" ]; then
    raise_pid_kwin "${pids%% *}"
    return 0
  fi
  # Nobody has herdr open: hand the most recently used tmux client over to it,
  # the same swap `prefix + H` does (config/tmux/notes.conf); detaching from
  # herdr re-attaches tmux.
  ctty="$(tmux list-clients -F '#{client_activity} #{client_tty}' 2>/dev/null | sort -n | tail -n 1 | cut -d' ' -f2)"
  [ -n "$ctty" ] || return 0
  tpid="$(term_pid_from_tty "$ctty" || true)"
  tmux detach-client -t "$ctty" -E "\"$hb\"; exec tmux attach" 2>/dev/null
  [ -n "$tpid" ] && raise_pid_kwin "$tpid"
  return 0
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
exec >/dev/null # Codex reads hook stdout as a JSON decision; stay silent.
payload="$(cat -)"
event="$(printf '%s' "$payload" | jq -r '.hook_event_name // ""' 2>/dev/null)"
msg="$(printf '%s' "$payload" | jq -r '.message // ""' 2>/dev/null)"
# Stop fires every turn-end and carries no message; give it its own text
# and route it through the focus-guarded path below (Notification is
# already focus-suppressed by CC itself, so it stays clickable/precise).
if [ -z "$msg" ]; then
  case "$event" in
    Stop) msg="✅ $AGENT 講完一輪了" ;;
    PermissionRequest) msg="🔐 $AGENT needs your approval" ;;
    *) msg="$AGENT needs your attention" ;;
  esac
fi

icon="$ICON_PATH"
[ "$AGENT" = "Claude" ] || icon="" # the sprite is Claude's
[ -f "$icon" ] || icon="starred"

title="$AGENT"
saved_pane="${TMUX_PANE:-}"
saved_sess=""
term_pid=""
term_app="${TERM_PROGRAM:-}"
client_tty=""

if [ -n "${TMUX:-}" ] && [ -n "$saved_pane" ]; then
  saved_sess="$(tmux display-message -p -t "$saved_pane" '#{session_name}' 2>/dev/null || true)"
  pane_loc="$(tmux display-message -p -t "$saved_pane" '#{session_name}:#{window_index}.#{pane_index}' 2>/dev/null || true)"
  cwd_base="$(tmux display-message -p -t "$saved_pane" '#{b:pane_current_path}' 2>/dev/null || true)"
  [ -n "$pane_loc" ] && title="$AGENT · $pane_loc"
  [ -n "$cwd_base" ] && title="$title · $cwd_base"
  tmux display-message "🔔 $title: $msg" 2>/dev/null
  client_tty="$(tmux list-clients -t "$saved_sess" -F '#{client_tty}' 2>/dev/null | head -1)"
  [ -n "$client_tty" ] && term_pid="$(term_pid_from_tty "$client_tty" || true)"
else
  cwd_base="$(basename "${PWD:-/}")"
  if in_herdr; then
    title="$title · herdr $HERDR_PANE_ID"
  elif [ -n "$term_app" ]; then
    title="$title · $term_app"
  fi
  [ -n "$cwd_base" ] && [ "$cwd_base" != "/" ] && title="$title · $cwd_base"
  term_pid="$(term_pid_from_tty "$(tty 2>/dev/null)" || true)"
fi

# ── tmux status light: ● waiting for input (Notification), ✓ turn done
# (Stop). Truth lives on the pane (@agent_status, keyed by $TMUX_PANE so
# pane splits stay unambiguous); a copy is aggregated onto the containing
# window so the window tab lights up. Cleared by the pane-focus-in hook
# in tmux.conf. Skipped when you're already looking at the pane — the
# light means "needs attention elsewhere". Over SSH this paints the
# REMOTE tmux (if any); the local tmux window lights via the BEL →
# window_bell_flag path instead. ──
paint_tmux_status() {
  [ -n "${TMUX:-}" ] && [ -n "$saved_pane" ] || return 0
  local v
  v="$(tmux display-message -p -t "$saved_pane" '#{?pane_active,1,0}#{?window_active,1,0}#{?session_attached,1,0}' 2>/dev/null)"
  [ "$v" = "111" ] && return 0
  local mark="●"
  [ "$event" = "Stop" ] && mark="✓"
  tmux set-option -pt "$saved_pane" @agent_status "$mark" 2>/dev/null || return 0
  local win
  win="$(tmux display-message -p -t "$saved_pane" '#{window_id}' 2>/dev/null)"
  [ -n "$win" ] && tmux set-option -wt "$win" @agent_status "$mark" 2>/dev/null
}
paint_tmux_status

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
      if in_herdr; then
        herdr_jump
      else
        tmux_restore "$saved_sess" "$saved_pane"
        [ -n "$term_pid" ] && raise_pid_kwin "$term_pid"
      fi
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
  local viewing view_term_pids
  compute_viewing
  local gicon="$icon" term_pids_js="${view_term_pids// /, }" entry="${CC_NOTIFY_DESKTOP_ENTRY:-Alacritty}"
  # JSON-encode every interpolated value: this KWin script runs in a
  # privileged context (callDBus to any service), so a value containing a
  # double-quote or JS (e.g. a crafted cwd basename in $title) could break
  # out of the string literal and inject code. `jq -Rs .` emits a safe,
  # fully-escaped JSON string literal (also valid JS); embed it WITHOUT
  # surrounding quotes since jq supplies them.
  local gicon_j title_j msg_j entry_j app_j
  app_j="$(printf '%s' "$AGENT" | jq -Rs .)"
  gicon_j="$(printf '%s' "$gicon" | jq -Rs .)"
  title_j="$(printf '%s' "$title" | jq -Rs .)"
  msg_j="$(printf '%s' "$msg" | jq -Rs .)"
  entry_j="$(printf '%s' "$entry" | jq -Rs .)"
  nlib_kwin_run "$(cat <<EOF
const w = workspace.activeWindow || workspace.activeClient;
const cls = w ? (w.resourceClass || "") : "";
const focusedAla = /alacritty/i.test(cls);
const viewing = $viewing;
const termPids = [$term_pids_js];
// When the agent's terminal windows are known (herdr), "focused on a
// terminal" has to mean one of THOSE windows, not just any Alacritty.
const onAgentTerm = termPids.length === 0 || (w && termPids.includes(w.pid));
// Quiet only when you're focused on Alacritty AND it's showing the agent's pane.
if (!(focusedAla && viewing && onAgentTerm)) {
  callDBus("org.freedesktop.Notifications", "/org/freedesktop/Notifications",
    "org.freedesktop.Notifications", "Notify",
    $app_j, 0, $gicon_j,
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
  local viewing view_term_pids
  compute_viewing
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

# ════════════════ remote channel (optional) ════════════════
# The one path that does not depend on a terminal being attached anywhere or
# on this machine having a desktop: needed when the agent runs on a box you
# only reach over SSH with herdr started by systemd, where no pane carries
# SSH_TTY and BEL/OSC have nowhere to go. Slack-compatible incoming webhook
# ({"text": ...}). The env file is parsed, never sourced.
remote_wants_event() {
  case " ${CC_NOTIFY_WEBHOOK_EVENTS:-Notification PermissionRequest} " in
    *" $event "*) return 0 ;;
  esac
  return 1
}

notify_remote() {
  local envf="${XDG_CONFIG_HOME:-$HOME/.config}/cc-notify/env" v
  if [ -r "$envf" ]; then
    v="$(sed -n 's/^CC_NOTIFY_WEBHOOK_URL=//p' "$envf" | tail -n 1)"
    [ -n "$v" ] && CC_NOTIFY_WEBHOOK_URL="${v%\"}" && CC_NOTIFY_WEBHOOK_URL="${CC_NOTIFY_WEBHOOK_URL#\"}"
    v="$(sed -n 's/^CC_NOTIFY_WEBHOOK_EVENTS=//p' "$envf" | tail -n 1)"
    [ -n "$v" ] && CC_NOTIFY_WEBHOOK_EVENTS="${v%\"}" && CC_NOTIFY_WEBHOOK_EVENTS="${CC_NOTIFY_WEBHOOK_EVENTS#\"}"
  fi
  [ -n "${CC_NOTIFY_WEBHOOK_URL:-}" ] || return 0
  remote_wants_event || return 0
  command -v curl >/dev/null 2>&1 || return 0
  local body
  body="$(jq -n --arg t "[$(hostname -s 2>/dev/null || echo host)] $title — $msg" '{text: $t}')" || return 0
  (curl -fsS -m 10 -X POST -H 'Content-Type: application/json' -d "$body" \
    "$CC_NOTIFY_WEBHOOK_URL" >/dev/null 2>&1 &)
}
notify_remote

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
