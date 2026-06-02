#!/usr/bin/env bash
# Shared helpers for the Claude Code notification hooks. Sourced by both
# cc-notify.sh (the Notification/Stop hook) and bell-notify.sh (Alacritty's
# bell.command handler, the SSH-receiving side). Centralises the bits that
# were duplicated across both: the KWin script-runner dance, the macOS
# frontmost-app query, the terminal-notifier toast, and the PATH fix-up.
#
# These functions hold the platform PRIMITIVES; the per-hook policy (which
# focus guard, what title/message, whether to attach a click action) stays
# in the calling script. No function here reads globals — everything comes
# in as arguments — so callers stay easy to reason about.
#
# NOTE: the Linux/KWin paths can only be exercised on KDE Wayland; they are
# unchanged byte-for-byte from the pre-refactor scripts but have NOT been
# re-run on Linux since extraction — verify on the Fedora/KDE box before
# relying on them.

# ── PATH fix-up for minimal-PATH launch contexts ──
# Alacritty's bell.command (and any GUI-launched hook) inherits launchd's
# /usr/bin:/bin, not the nix profile, so a bare `terminal-notifier` /
# `notify-send` / `tmux` lookup fails. Prepend the usual nix profile +
# system locations so the real tools are found.
nlib_setup_path() {
  export PATH="$HOME/.local/state/nix/profile/bin:$HOME/.nix-profile/bin:/run/current-system/sw/bin:/etc/profiles/per-user/$USER/bin:/usr/bin:/bin:$PATH"
}

# ── Linux/KDE: run a KWin script ──
# KDE Wayland blocks wmctrl/xdotool/kdotool and queryWindowInfo is
# interactive, so the compositor's own privileged JS context is the only
# way to read the active window or callDBus the freedesktop Notify. This is
# the load → get script-id → run → unload boilerplate, shared by every KWin
# caller; the JS body (which differs per caller) comes in as $1. No-ops
# silently without gdbus/KWin (GNOME/sway/bare X).
nlib_kwin_run() {
  command -v gdbus >/dev/null 2>&1 || return 0
  gdbus call --session --dest org.kde.KWin --object-path /Scripting \
    --method org.kde.kwin.Scripting.loadScript / >/dev/null 2>&1 || return 0
  local js; js="$(mktemp /tmp/cc-kwin-XXXXXX.js)" || return 0
  printf '%s\n' "$1" > "$js"
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

# ── macOS: name of the frontmost GUI application ──
# System Events reports the focused app; callers compare it against their
# own terminal list (cc-notify guards only on Alacritty; bell guards on any
# terminal). Empty on failure / missing osascript.
nlib_frontmost_app() {
  command -v osascript >/dev/null 2>&1 || return 0
  osascript -e 'tell application "System Events" to name of first application process whose frontmost is true' 2>/dev/null
}

# ── macOS: post a terminal-notifier toast ──
# Args: <title> <message> <icon-path> [execute]
# The sprite goes on the right via -contentImage (-appIcon is ignored on
# recent macOS, where the main icon is always the posting app's own). When
# an <execute> command is supplied (cc-notify's click → --jump), stale
# terminal-notifier waiters are reaped first: each -execute toast keeps a
# process alive to catch the click, and on macOS (NSUserNotification
# deprecated) several piled-up waiters of the same bundle id drop the click
# callback, silently breaking clicks. Reaping keeps the newest toast the
# single live one. Falls back to osascript display-notification (no click,
# no icon) when terminal-notifier isn't installed.
nlib_toast_macos() {
  local title="$1" msg="$2" icon="$3" execute="${4:-}"
  if command -v terminal-notifier >/dev/null 2>&1; then
    local img=()
    [ -f "$icon" ] && img=(-contentImage "$icon")
    local exec_arg=()
    if [ -n "$execute" ]; then
      pkill -f 'terminal-notifier.app/Contents/MacOS' 2>/dev/null || true
      exec_arg=(-execute "$execute")
    fi
    terminal-notifier -title "$title" -message "$msg" "${img[@]}" "${exec_arg[@]}" \
      >/dev/null 2>&1 &
    disown 2>/dev/null || true
  else
    osascript -e "display notification \"$msg\" with title \"$title\"" >/dev/null 2>&1 || true
  fi
}
