#!/usr/bin/env bash
# Codex counterpart of sync-plugins.sh: bring a fresh ~/.codex up to the same
# tool set Claude Code gets. Idempotent; every step is skipped once done.
#
# Content (global instructions, skills, the config.toml seed) is NOT handled
# here: home/codex.nix links/merges it during the switch that runs before this.
# This script only covers tool-owned state that Codex and the installers write
# themselves, which is why it shells out to their CLIs instead of templating
# files.
set -euo pipefail

command -v codex >/dev/null 2>&1 || exit 0 # Codex is optional on a machine.

CODEX_DIR="${CODEX_HOME:-$HOME/.codex}"

# --- MCP servers (the Claude side gets these bundled inside plugins) ---
# "<name> <command...>"
MCP_SERVERS=(
  "context7 npx -y @upstash/context7-mcp"
)
for entry in "${MCP_SERVERS[@]}"; do
  read -r name cmd <<<"$entry"
  if codex mcp list 2>/dev/null | grep -qE "^${name}[[:space:]]"; then
    echo "skip: codex mcp $name (already configured)"
  else
    # shellcheck disable=SC2086 # word splitting of $cmd is intended
    codex mcp add "$name" -- $cmd
  fi
done

# --- GSD (npm installer, owns ~/.codex/{get-shit-done,agents,skills/gsd-*,hooks}) ---
# It bakes a /nix/store node path into hooks.json; home.activation.fixGsdNodePath
# rewrites that to the profile symlink on the next switch.
if [[ -f "$CODEX_DIR/get-shit-done/VERSION" ]]; then
  echo "skip: get-shit-done for codex (already installed: v$(cat "$CODEX_DIR/get-shit-done/VERSION"))"
else
  npx -y --package=get-shit-done-cc@latest -- get-shit-done-cc --codex --global --config-dir "$CODEX_DIR"
fi

# --- herdr agent-state hook (agent status in the sidebar and phone push) ---
if command -v herdr >/dev/null 2>&1; then
  if herdr integration status 2>/dev/null | grep -q '^codex: current'; then
    echo "skip: herdr codex integration (current)"
  else
    herdr integration install codex
  fi
fi

# --- Desktop/remote notifications: reuse the Claude Code hook ---
# .claude/hooks/cc-notify.sh is agent-agnostic (`--agent codex`). Codex has no
# Notification event; PermissionRequest is its "needs you", Stop its "turn
# finished". hooks.json is shared with GSD and herdr, so entries are merged in
# with jq rather than templated, under `.hooks.<Event>` like herdr's own.
NOTIFY_HOOK="$HOME/.claude/hooks/cc-notify.sh"
HOOKS_JSON="$CODEX_DIR/hooks.json"
if [[ -e "$NOTIFY_HOOK" ]] && command -v jq >/dev/null 2>&1; then
  [[ -s "$HOOKS_JSON" ]] || echo '{}' >"$HOOKS_JSON"
  notify_cmd="bash '$NOTIFY_HOOK' --agent codex"
  for ev in Stop PermissionRequest; do
    if jq -e --arg ev "$ev" '[.hooks[$ev][]?.hooks[]?.command // empty] | any(test("cc-notify\\.sh"))' "$HOOKS_JSON" >/dev/null 2>&1; then
      echo "skip: codex $ev notify hook (already registered)"
    else
      tmp="$(mktemp)"
      jq --arg ev "$ev" --arg cmd "$notify_cmd" \
        '.hooks[$ev] = ((.hooks[$ev] // []) + [{hooks: [{type: "command", command: $cmd, timeout: 10}]}])' \
        "$HOOKS_JSON" >"$tmp" && mv "$tmp" "$HOOKS_JSON"
      echo "added: codex $ev notify hook"
    fi
  done
fi

# --- Curated plugins (the official catalogue; needs `codex login`) ---
# The catalogue lives in the reserved remote marketplace below and is empty
# while logged out. Installed state is NOT recorded in config.toml, so the
# JSON listing is the only reliable "already installed" check.
MARKETPLACE=openai-curated-remote
CURATED_PLUGINS=(
  superpowers # same framework as the Claude Code plugin
  # github    # in the catalogue, but its connector wants interactive OAuth
)
# `codex login status` exits non-zero when logged out; with pipefail a direct
# pipe into grep would make this test false for exactly the case it looks for.
login_status="$(codex login status 2>&1 || true)"
if grep -qi 'not logged in' <<<"$login_status"; then
  echo "todo: run 'codex login', then re-run this script to install: ${CURATED_PLUGINS[*]}"
elif ! command -v jq >/dev/null 2>&1; then
  echo "WARN: jq not found; cannot check curated plugins" >&2
else
  catalogue="$(codex plugin list --available --json 2>/dev/null || true)"
  for p in "${CURATED_PLUGINS[@]}"; do
    state="$(jq -r --arg n "$p" --arg m "$MARKETPLACE" \
      '[.. | objects | select(.name? == $n and .marketplaceName? == $m)][0].installed // "missing"' \
      <<<"$catalogue" 2>/dev/null || echo missing)"
    case "$state" in
      true) echo "skip: codex plugin $p (already installed)" ;;
      false) codex plugin add "$p@$MARKETPLACE" ;;
      *) echo "WARN: $p not found in $MARKETPLACE (catalogue unavailable?)" >&2 ;;
    esac
  done
fi

# --- Bridge plugin skills into ~/.agents/skills ---
# Verified on codex 0.154: an installed+enabled remote plugin does NOT surface its
# skills to the model (neither in `codex exec` nor when @-mentioned), while any
# skill directory symlinked into ~/.agents/skills does. So the CLI install above
# handles download/updates and these links make the skills actually usable.
# The cache path contains the version, hence re-pointed on every run.
SKILLS_DIR="$HOME/.agents/skills"
mkdir -p "$SKILLS_DIR"
for p in "${CURATED_PLUGINS[@]}"; do
  src="$(find "$CODEX_DIR/plugins/cache/$MARKETPLACE/$p" -mindepth 2 -maxdepth 2 -type d -name skills 2>/dev/null | sort -V | tail -n 1)"
  [[ -n "$src" ]] || continue
  linked=0
  for dir in "$src"/*/; do
    [[ -f "$dir/SKILL.md" ]] || continue
    name="$(basename "$dir")"
    dest="$SKILLS_DIR/$name"
    # Never clobber a skill that is not ours: a real directory, or a link that
    # points outside the plugin cache (e.g. a user skill linked by home-manager).
    if [[ -e "$dest" || -L "$dest" ]]; then
      target="$(readlink "$dest" 2>/dev/null || true)"
      [[ "$target" == "$CODEX_DIR/plugins/cache/"* ]] || { echo "keep: $name (not a bridged link)"; continue; }
    fi
    ln -sfn "${dir%/}" "$dest"
    linked=$((linked + 1))
  done
  echo "bridged: $linked $p skills -> $SKILLS_DIR ($(basename "$(dirname "$src")"))"
done
# Drop bridged links whose target vanished (plugin removed or skill renamed).
find "$SKILLS_DIR" -maxdepth 1 -type l ! -exec test -e {} \; -lname "$CODEX_DIR/plugins/cache/*" -delete 2>/dev/null || true
