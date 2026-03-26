{ pkgs, config, dotfiles, ... }:
let
  filePreview = "bat --color=always {}";
  dirPreview = "eza --color always --tree --level 1 {} | less";

  yankField = field:
    "ctrl-y:execute-silent(echo -n {${toString field}..} | ${dotfiles.directory}/config/zsh/autoload/yank)+abort";

  # catppuccin macchiato sky (catppuccin/nix doesn't have skim support)
  catppuccinColors = builtins.concatStringsSep "," [
    "fg:#cad3f5"
    "bg:#24273a"
    "hl:#ed8796"
    "fg+:#cad3f5"
    "bg+:#363a4f"
    "hl+:#ed8796"
    "info:#91d7e3"
    "prompt:#91d7e3"
    "pointer:#f4dbd6"
    "marker:#b7bdf8"
    "spinner:#f4dbd6"
    "header:#ed8796"
  ];
in
{
  programs.skim = {
    enable = true;
    package = pkgs.unstable.skim;
    defaultOptions = [
      "--layout=reverse"
      "--cycle"
      "--color=${catppuccinColors}"
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
