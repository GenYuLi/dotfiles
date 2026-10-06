# OpenAI Codex CLI, set up to share what is already maintained for Claude Code.
#
# The binary itself is NOT managed here: it comes from the official standalone
# installer into ~/.local/bin and updates itself with `codex update` (same stance
# as herdr). This module only makes Codex read the same *content*:
#
#   ~/.codex/AGENTS.md      = .claude/CLAUDE.md + .codex/AGENTS.codex.md, a Codex-only
#                             section pointing at Claude Code's file-based memory,
#                             so both agents share one curated memory. Composed
#                             here because Codex reads exactly one global file and
#                             has no include syntax.
#   ~/.agents/skills/<name> = every user-authored skill tracked under
#                             .claude/skills (same SKILL.md format; Codex follows
#                             symlinks).
#   ~/.codex/config.toml    = owned by Codex (it creates the file at first login and
#                             rewrites it for MCP servers and per-project trust),
#                             so .codex/config.seed.toml is merged in, not linked.
#
# Plugins, MCP servers and hooks are tool state, not content: see
# .codex/sync-plugins.sh, which `dotswitch` runs after a switch.
#
# ~/.codex itself must never be linked wholesale: it holds auth.json, sqlite
# state and caches, and this repository is public.
{
  pkgs,
  lib,
  config,
  dotfiles,
  ...
}:
let
  symlinkDotfiles = path: config.lib.file.mkOutOfStoreSymlink "${dotfiles.directory}/${path}";

  # The flake source only contains git-tracked files, so this is exactly the
  # user-authored set: installer-owned gsd-* dirs are gitignored and the
  # claude.ai `synced/` bucket is untracked, neither shows up here.
  ownSkills = lib.attrNames (
    lib.filterAttrs (_: type: type == "directory") (builtins.readDir ../.claude/skills)
  );

in
{
  home.file = {
    ".codex/AGENTS.md".text =
      builtins.readFile ../.claude/CLAUDE.md + builtins.readFile ../.codex/AGENTS.codex.md;
  }
  // lib.listToAttrs (
    map (name: {
      name = ".agents/skills/${name}";
      value.source = symlinkDotfiles ".claude/skills/${name}";
    }) ownSkills
  );

  home.activation.seedCodexConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    cfg="${config.home.homeDirectory}/.codex/config.toml"
    seed=${../.codex/config.seed.toml}
    if [ ! -e "$cfg" ]; then
      run install -Dm600 "$seed" "$cfg"
      echo "seedCodexConfig: created $cfg from the seed"
    elif ! ${pkgs.gnugrep}/bin/grep -q '^project_doc_fallback_filenames' "$cfg"; then
      # Codex got there first (it writes config.toml at login). Prepend, so the
      # seed's bare keys stay top-level instead of falling into a [table].
      tmp="$(mktemp)"
      { ${pkgs.gnugrep}/bin/grep -v '^#' "$seed" | ${pkgs.gnused}/bin/sed '/./,$!d'; echo; cat "$cfg"; } > "$tmp"
      run install -m600 "$tmp" "$cfg"
      rm -f "$tmp"
      echo "seedCodexConfig: merged seed keys into existing $cfg"
    fi
  '';
}
