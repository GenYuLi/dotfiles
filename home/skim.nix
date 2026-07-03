{ pkgs, config, dotfiles, ... }:
let
  filePreview = "bat --color=always {}";
  dirPreview = "eza --color always --tree --level 1 {} | less";

  yankField = field:
    "ctrl-y:execute-silent(echo -n {${toString field}..} | ${dotfiles.directory}/config/zsh/autoload/yank)+abort";

  # gruvbox-material dark medium (catppuccin/nix doesn't have skim support,
  # so colours are set manually to match nvim + tmux + alacritty)
  gruvboxColors = builtins.concatStringsSep "," [
    "fg:#d4be98"
    "bg:#1d2021"
    "hl:#ea6962"
    "fg+:#d4be98"
    "bg+:#3c3836"
    "hl+:#ea6962"
    "info:#89b482"
    "prompt:#89b482"
    "pointer:#d3869b"
    "marker:#a9b665"
    "spinner:#d3869b"
    "header:#7daea3"
  ];
in
{
  programs.skim = {
    enable = true;
    package = pkgs.skim;
    defaultOptions = [
      "--layout=reverse"
      "--cycle"
      "--color=${gruvboxColors}"
      "--bind 'ctrl-u:preview-page-up,ctrl-d:preview-page-down'"
      "--bind '${yankField 1}'"
    ];
    fileWidgetCommand = "fd --follow";
    fileWidgetOptions = [
      "--preview '([[ -f {} ]] && ${filePreview}) || ([[ -d {} ]] && ${dirPreview}) || echo {} 2> /dev/null | head -200'"
    ];
    changeDirWidgetOptions = [
      "--preview '${dirPreview}'"
    ];
    historyWidgetOptions = [
      "--bind '${yankField 2}'"
    ];
  };
}
