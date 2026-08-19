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

# GSD (get-shit-done) is npm-based, not a marketplace plugin. Its files are
# deliberately gitignored (.claude/{skills,agents,hooks}/gsd-*) because the
# installer owns them and self-updates via its SessionStart hook / `/gsd:update`.
if [[ -f "$HOME/.claude/get-shit-done/VERSION" ]]; then
  echo "skip: get-shit-done (already installed: v$(cat "$HOME/.claude/get-shit-done/VERSION"))"
else
  npx -y --package=get-shit-done-cc@latest -- get-shit-done-cc --claude --global
fi
