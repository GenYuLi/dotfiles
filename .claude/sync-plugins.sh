#!/usr/bin/env bash
# Sync Claude Code plugins (user scope) on a new machine.
# Idempotent: skips plugins already recorded in installed_plugins.json.
# Plugin state lives in ~/.claude/plugins/ + ~/.claude/settings.json, both of
# which Claude Code mutates itself — so we sync via CLI instead of nix symlinks.
set -euo pipefail

MARKETPLACE=claude-plugins-official
INSTALLED_JSON="$HOME/.claude/plugins/installed_plugins.json"

PLUGINS=(
  superpowers        # process framework: brainstorm/plan/TDD/review
  mattpocock-skills  # lightweight single-purpose skills: /tdd /grill-me /diagnosing-bugs ...
  skill-creator
  context7
  github
  code-review
  feature-dev
  claude-code-setup
  rust-analyzer-lsp
  pyright-lsp
  clangd-lsp
)

for p in "${PLUGINS[@]}"; do
  if [[ -f "$INSTALLED_JSON" ]] && grep -q "\"$p@$MARKETPLACE\"" "$INSTALLED_JSON"; then
    echo "skip: $p (already installed)"
  else
    claude plugin install "$p@$MARKETPLACE" --scope user
  fi
done

# Third-party marketplaces: "<plugin>@<marketplace> <owner/repo or git URL>".
# Each marketplace is added on demand (idempotent) before installing. A failed
# add (e.g. a private repo before the GitHub SSH key exists) only skips that
# plugin; rerun this script once access works.
THIRD_PARTY=(
  "ponytail@ponytail DietrichGebert/ponytail"  # lazy-senior-dev mode: YAGNI / stdlib-first / least code; needs node on PATH
  "withers-core@withers-skills git@github.com:GenYuLi/skills.git"  # own skills (private, needs GitHub SSH): visual-explainer, arch-analysis, /standup ...
)

for entry in "${THIRD_PARTY[@]}"; do
  read -r id repo <<<"$entry"
  mk="${id#*@}"
  if [[ -f "$INSTALLED_JSON" ]] && grep -q "\"$id\"" "$INSTALLED_JSON"; then
    echo "skip: $id (already installed)"
    continue
  fi
  if ! claude plugin marketplace list 2>/dev/null | grep -qE "^[[:space:]]*❯ $mk\$"; then
    if ! claude plugin marketplace add "$repo"; then
      echo "WARN: could not add marketplace $mk ($repo); skipped $id" >&2
      continue
    fi
  fi
  claude plugin install "$id" --scope user
done

# Desktop/remote notifications: cc-notify.sh on Notification ("needs you") and
# Stop ("turn finished"). settings.json is Claude Code's own file (GSD writes
# hooks there too), so entries are merged in with jq rather than templated.
# The Slack webhook URL is per machine: ~/.config/cc-notify/env, see cc-notify.sh.
NOTIFY_HOOK="$HOME/.claude/hooks/cc-notify.sh"
SETTINGS_JSON="$HOME/.claude/settings.json"
if [[ -e "$NOTIFY_HOOK" ]] && command -v jq >/dev/null 2>&1; then
  [[ -s "$SETTINGS_JSON" ]] || echo '{}' >"$SETTINGS_JSON"
  for ev in Notification Stop; do
    if jq -e --arg ev "$ev" '[.hooks[$ev][]?.hooks[]?.command // empty] | any(test("cc-notify\\.sh"))' "$SETTINGS_JSON" >/dev/null 2>&1; then
      echo "skip: $ev notify hook (already registered)"
    else
      tmp="$(mktemp)"
      jq --arg ev "$ev" --arg cmd "bash \"$NOTIFY_HOOK\"" \
        '.hooks[$ev] = ((.hooks[$ev] // []) + [{hooks: [{type: "command", command: $cmd, timeout: 10}]}])' \
        "$SETTINGS_JSON" >"$tmp" && mv "$tmp" "$SETTINGS_JSON"
      echo "added: $ev notify hook"
    fi
  done
fi

# GSD (get-shit-done) is npm-based, not a marketplace plugin. Its files are
# deliberately gitignored (.claude/{skills,agents,hooks}/gsd-*) because the
# installer owns them and self-updates via its SessionStart hook / `/gsd:update`.
if [[ -f "$HOME/.claude/get-shit-done/VERSION" ]]; then
  echo "skip: get-shit-done (already installed: v$(cat "$HOME/.claude/get-shit-done/VERSION"))"
else
  npx -y --package=get-shit-done-cc@latest -- get-shit-done-cc --claude --global
fi
