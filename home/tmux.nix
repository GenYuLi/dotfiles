{
  pkgs,
  config,
  dotfiles,
  ...
}:
let
  dotDir = "${dotfiles.directory}";
  dataHome = "${config.xdg.dataHome}/tmux";
in
{
  catppuccin.tmux.enable = false;

  programs.tmux = {
    enable = true;
    package = pkgs.unstable.tmux;
    sensibleOnTop = false;
    terminal = "xterm-256color";
    shell = "${pkgs.zsh}/bin/zsh";
    plugins = with pkgs.tmuxPlugins; [
      {
        plugin = prefix-highlight;
        extraConfig = ''
          source-file ${dotDir}/config/tmux/tmux.conf
          source-file ${dotDir}/config/tmux/notes.conf
        '';
      }
      {
        plugin = fingers;
        extraConfig = "set -g @fingers-key C-f";
      }
      {
        plugin = t-smart-tmux-session-manager;
        extraConfig = "set -g @t-bind 'F4'";
      }
      {
        plugin = extrakto;
        extraConfig = ''
          set -g @extrakto_copy_key "ctrl-y"
          set -g @extrakto_insert_key "enter"
          set -g @extrakto_clip_tool "bash ${dotDir}/config/zsh/autoload/yank"
        '';
      }
      {
        plugin = logging;
        extraConfig = ''
          set -g @save-complete-history-path "${dataHome}/log"
          set -g @save-complete-history-key 'P'
        '';
      }
      {
        plugin = resurrect;
        extraConfig = ''
          set -g @resurrect-default-processes "ssh"
          set -g @resurrect-capture-pane-contents "on"
          set -g @resurrect-dir "${dataHome}/resurrect"
        '';
      }
      {
        # Auto-save (15 min) + auto-restore for resurrect. Continuum's own
        # trigger rides on status-right, which vim-tpipeline OVERRIDES for the
        # whole lifetime of a focused nvim (see tpipeline.lua VimLeavePre unset)
        # — so with only the default hook, saves silently stop while nvim is
        # open. Anchor a second trigger in window-status-current-format, which
        # tpipeline never touches: the script prints nothing and self-guards
        # the interval, so double-firing is harmless and invisible.
        plugin = continuum;
        extraConfig = ''
          set -g @continuum-restore "on"
          set -g @continuum-save-interval "15"
          set -ga window-status-current-format "#(${continuum}/share/tmux-plugins/continuum/scripts/continuum_save.sh)"
        '';
      }
      tmux-fzf
    ];
  };
}
