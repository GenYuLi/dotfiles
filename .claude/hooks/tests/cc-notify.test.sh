#!/usr/bin/env bash
# Behaviour tests for cc-notify.sh. The hook's whole job is side effects (desktop
# toasts, KWin scripts, tmux/herdr commands, a webhook), so every external command
# is replaced by a recording shim on PATH and the assertions read what the hook
# asked those commands to do. Run: bash .claude/hooks/tests/cc-notify.test.sh
set -u

# The suite is usually launched from inside tmux (and maybe herdr). Those
# variables decide which branch the hook takes, so each case must set them
# explicitly; anything inherited would silently test the wrong branch.
unset TMUX TMUX_PANE HERDR_ENV HERDR_PANE_ID HERDR_TAB_ID HERDR_WORKSPACE_ID SSH_CONNECTION SSH_TTY

HOOK="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/cc-notify.sh"
REAL_PATH="$PATH"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
SHIMS="$WORK/shims"; mkdir -p "$SHIMS"
pass=0; fail=0

# ── shims ──
shim() { printf '#!/usr/bin/env bash\n%s\n' "$2" > "$SHIMS/$1"; chmod +x "$SHIMS/$1"; }
shim notify-send 'echo "notify-send $*" >> "$LOG"; [ "${SHIM_CLICK:-0}" = 1 ] && echo default; exit 0'
shim curl        'echo "curl $*" >> "$LOG"; exit 0'
shim tty         'echo "not a tty"; exit 1'
shim pgrep       '[ "$*" = "-x herdr" ] && printf "%s\n" ${SHIM_HERDR_PIDS:-}; exit 0'
shim gdbus '
for a in "$@"; do case "$a" in /tmp/cc-kwin-*.js) cat "$a" >> "$LOG.js"; echo "//--" >> "$LOG.js";; esac; done
echo "gdbus $*" >> "$LOG"; echo "(7,)"'
shim herdr '
echo "herdr $*" >> "$LOG"
if [ "$1 $2" = "api snapshot" ]; then
  printf "{\"result\":{\"snapshot\":{\"panes\":[{\"pane_id\":\"w1:p1\",\"focused\":%s}]}}}\n" "${SHIM_HERDR_FOCUSED:-false}"
fi'
shim tmux '
echo "tmux $*" >> "$LOG"
case "$*" in
  *"list-clients"*) [ -n "${SHIM_TMUX_CLIENTS:-}" ] && printf "%s\n" "$SHIM_TMUX_CLIENTS";;
  *"pane_active"*)  echo "${SHIM_TMUX_V:-000}";;
  *"session_name}:"*) echo "main:1.0";;
  *"session_name"*) echo "main";;
  *"pane_current_path"*) echo "proj";;
  *"window_id"*) echo "@1";;
esac'
# ps backed by a canned table: "pid ppid tty comm args...". Invoked as
# `ps -o <field>= -p <pid>` / `ps -o pid= -t <tty>`, so the operand is $4.
shim ps '
t="${SHIM_PS_TABLE:-/dev/null}"
case "$*" in
  "-o args= -p "*) awk -v p="$4" "\$1==p{\$1=\$2=\$3=\$4=\"\"; sub(/^ +/,\"\"); print}" "$t";;
  "-o tty= -p "*)  awk -v p="$4" "\$1==p{print \$3}" "$t";;
  "-o comm= -p "*) awk -v p="$4" "\$1==p{print \$4}" "$t";;
  "-o ppid= -p "*) awk -v p="$4" "\$1==p{print \$2}" "$t";;
  "-o pid= -t "*)  awk -v y="$4" "\$3==y{print \$1}" "$t";;
esac'

# Process table: 9001 = herdr server (no tty); 9002 = a herdr client inside
# Alacritty (pid 4242); 9003 = the PWA gateway client (parent is node, no terminal).
cat > "$WORK/ps.table" <<'T'
9001 1    ?     herdr     /home/u/.local/bin/herdr server
9002 9000 pts/5 herdr     /home/u/.local/bin/herdr
9000 4242 pts/5 zsh       zsh
4242 1    ?     alacritty alacritty
9003 8000 pts/9 herdr     /home/u/.local/bin/herdr
8000 1    ?     node      node server/index.ts
T

# ── runner: run_hook <event> [hook args...]; env comes from the caller ──
run_hook() {
  local event="$1"; shift
  LOG="$WORK/log"; : > "$LOG"; : > "$LOG.js"
  printf '{"hook_event_name":"%s","message":"%s"}' "$event" "${MSG:-}" |
    env -i PATH="$SHIMS:$REAL_PATH" HOME="$WORK/home" LOG="$LOG" \
      SHIM_PS_TABLE="$WORK/ps.table" \
      SHIM_CLICK="${SHIM_CLICK:-0}" SHIM_HERDR_PIDS="${SHIM_HERDR_PIDS:-}" \
      SHIM_HERDR_FOCUSED="${SHIM_HERDR_FOCUSED:-false}" SHIM_TMUX_V="${SHIM_TMUX_V:-000}" \
      SHIM_TMUX_CLIENTS="${SHIM_TMUX_CLIENTS:-}" \
      ${TMUX:+TMUX="$TMUX"} ${TMUX_PANE:+TMUX_PANE="$TMUX_PANE"} \
      ${HERDR_ENV:+HERDR_ENV="$HERDR_ENV"} ${HERDR_PANE_ID:+HERDR_PANE_ID="$HERDR_PANE_ID"} \
      ${HERDR_TAB_ID:+HERDR_TAB_ID="$HERDR_TAB_ID"} \
      bash "$HOOK" "$@" > "$WORK/stdout" 2> "$WORK/stderr"
  # the clickable toast runs in a detached subshell; give it a moment
  for _ in 1 2 3 4 5 6 7 8 9 10; do [ -s "$LOG" ] && break; command sleep 0.1; done
  command sleep 0.3
}
ok()   { pass=$((pass + 1)); printf '  ok   %s\n' "$1"; }
bad()  { fail=$((fail + 1)); printf '  FAIL %s\n       %s\n' "$1" "$2"; }
has()     { grep -qF -- "$2" "$1"; }
expect()  { if has "$2" "$3"; then ok "$1"; else bad "$1" "expected to find: $3"; fi; }
refute()  { if has "$2" "$3"; then bad "$1" "expected NOT to find: $3"; else ok "$1"; fi; }
in_herdr() { HERDR_ENV=1 HERDR_PANE_ID=w1:p1 HERDR_TAB_ID=w1:t1 "$@"; }
mkdir -p "$WORK/home"

echo "focus guard for Stop (turn finished)"
SHIM_HERDR_PIDS="9001" in_herdr run_hook Stop
expect "agent in herdr, nobody attached to herdr -> must not be treated as 'being watched'" "$LOG.js" "const viewing = 0;"

SHIM_HERDR_PIDS="9001 9002" SHIM_HERDR_FOCUSED=true in_herdr run_hook Stop
expect "herdr client open in a terminal and the pane is focused -> may stay quiet" "$LOG.js" "const viewing = 1;"
expect "quiet only if THAT terminal window is the focused one" "$LOG.js" "const termPids = [4242];"

SHIM_HERDR_PIDS="9001 9002" SHIM_HERDR_FOCUSED=false in_herdr run_hook Stop
expect "herdr client open but looking at another pane -> notify" "$LOG.js" "const viewing = 0;"

SHIM_HERDR_PIDS="9001 9003" SHIM_HERDR_FOCUSED=true in_herdr run_hook Stop
expect "only the phone gateway is attached (no terminal window) -> notify" "$LOG.js" "const viewing = 0;"

TMUX=/tmp/x TMUX_PANE=%1 SHIM_TMUX_V=111 run_hook Stop
expect "regression: tmux pane on screen -> may stay quiet" "$LOG.js" "const viewing = 1;"
TMUX=/tmp/x TMUX_PANE=%1 SHIM_TMUX_V=010 run_hook Stop
expect "regression: tmux pane not on screen -> notify" "$LOG.js" "const viewing = 0;"

echo "title"
SHIM_HERDR_PIDS="9001" MSG="need input" in_herdr run_hook Notification
expect "toast title says the agent lives in herdr and which pane" "$LOG" "herdr w1:p1"

echo "clicking the toast"
SHIM_CLICK=1 SHIM_HERDR_PIDS="9001" SHIM_TMUX_CLIENTS="1700000000 /dev/pts/3" MSG="need input" in_herdr run_hook Notification
expect "no herdr client anywhere -> flip the most recent tmux client over to herdr" "$LOG" "tmux detach-client -t /dev/pts/3 -E"
expect "…and land on the agent's tab" "$LOG" "herdr tab focus w1:t1"

SHIM_CLICK=1 SHIM_HERDR_PIDS="9001 9002" SHIM_TMUX_CLIENTS="1700000000 /dev/pts/3" MSG="need input" in_herdr run_hook Notification
refute "herdr already open in a terminal -> do not hijack a tmux client" "$LOG" "detach-client"
expect "…raise that terminal window instead" "$LOG.js" "const target = 4242;"

echo "codex"
SHIM_HERDR_PIDS="9001" in_herdr run_hook PermissionRequest --agent codex
expect "PermissionRequest is Codex's 'needs you' and gets a Codex-titled toast" "$LOG" "notify-send"
expect "…titled Codex, not Claude" "$LOG" "Codex"
if [ -s "$WORK/stdout" ]; then bad "codex parses hook stdout as a decision -> stdout must stay empty" "got: $(head -c 80 "$WORK/stdout")"; else ok "codex parses hook stdout as a decision -> stdout must stay empty"; fi

echo "remote webhook slot"
mkdir -p "$WORK/home/.config/cc-notify"
printf 'CC_NOTIFY_WEBHOOK_URL=https://hooks.example.invalid/T000/B000\n' > "$WORK/home/.config/cc-notify/env"
SHIM_HERDR_PIDS="9001" MSG="need input" in_herdr run_hook Notification
expect "webhook configured -> 'needs you' is also posted there" "$LOG" "curl"
expect "…to the configured URL" "$LOG" "https://hooks.example.invalid/T000/B000"
SHIM_HERDR_PIDS="9001" in_herdr run_hook Stop
refute "'turn finished' is not posted by default (too chatty for a channel)" "$LOG" "curl"
rm -f "$WORK/home/.config/cc-notify/env"
SHIM_HERDR_PIDS="9001" MSG="need input" in_herdr run_hook Notification
refute "no webhook configured -> nothing leaves the machine" "$LOG" "curl"

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
