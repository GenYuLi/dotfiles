{ pkgs, lib, nixgl, dotfiles, ... }:
let
  nixGLWrap = pkg:
    let
      nixGLDefault = nixgl.packages.${pkgs.system}.nixGLIntel;
    in
    pkgs.runCommand "${pkg.name}-nixgl" { nativeBuildInputs = [ pkgs.makeWrapper ]; } ''
      mkdir -p $out/bin
      for bin in ${pkg}/bin/*; do
        makeWrapper ${nixGLDefault}/bin/nixGLIntel $out/bin/$(basename $bin) \
          --argv0 $(basename $bin) \
          --add-flags "$bin"
      done
    '';
in
{
  # gruvbox-material for the terminal (matches nvim + tmux). The global
  # catppuccin module themes alacritty by default, so turn it off here and
  # supply the palette below explicitly.
  catppuccin.alacritty.enable = false;

  programs.alacritty = {
    enable = true;
    package = if pkgs.stdenv.isLinux then nixGLWrap pkgs.alacritty else pkgs.alacritty;
    settings = {
      terminal.shell = {
        program = "${pkgs.zsh}/bin/zsh";
      };
      env = {
        TERM = "xterm-256color";
      } // (lib.optionalAttrs pkgs.stdenv.isDarwin {
        # NOTE: ssh with `-Y` to setup remote DISPLAY properly
        # remember to start xquartz
        DISPLAY = ":0";
      });
      font = {
        normal.family = "Maple Mono Normal NF CN";
        size = 16.5;
      };
      window = {
        dynamic_padding = true;
        option_as_alt = "Both";
      };
      # On bell, run the focus-guarded notifier: a real desktop toast only
      # when Alacritty isn't focused. This is how Claude Code notifications
      # reach the local machine over SSH — cc-notify.sh's SSH branch writes
      # a BEL byte, which the local Alacritty turns into this command.
      bell.command = {
        program = "${pkgs.bash}/bin/bash";
        args = [ "${dotfiles.directory}/.claude/hooks/bell-notify.sh" ];
      };
      # gruvbox-material (dark, hard — matches nvim). ANSI slots mirror the
      # colorscheme's own g:terminal_color_* (bright == normal, black = #504945),
      # so the terminal matches nvim exactly.
      colors = {
        primary = {
          background = "#1d2021";
          foreground = "#d4be98";
        };
        cursor = {
          text = "#1d2021";
          cursor = "#d4be98";
        };
        vi_mode_cursor = {
          text = "#1d2021";
          cursor = "#7daea3";
        };
        selection = {
          text = "#d4be98";
          background = "#3c3836";
        };
        normal = {
          black = "#504945";
          red = "#ea6962";
          green = "#a9b665";
          yellow = "#d8a657";
          blue = "#7daea3";
          magenta = "#d3869b";
          cyan = "#89b482";
          white = "#d4be98";
        };
        bright = {
          black = "#504945";
          red = "#ea6962";
          green = "#a9b665";
          yellow = "#d8a657";
          blue = "#7daea3";
          magenta = "#d3869b";
          cyan = "#89b482";
          white = "#d4be98";
        };
        indexed_colors = [
          { index = 16; color = "#e78a4e"; }
          { index = 17; color = "#ddc7a1"; }
          { index = 18; color = "#274d7a"; }
        ];
      };
      keyboard = {
        # NOTE: showkey -a
        bindings = [
          { key = "C"; mods = "Control|Shift"; action = "Copy"; }
          { key = "V"; mods = "Control|Shift"; action = "Paste"; }
          { key = "N"; mods = "Control|Shift"; action = "SpawnNewInstance"; }
          { key = "W"; mods = "Control|Shift"; chars = "\\u001BK"; }
          { key = "T"; mods = "Control|Shift"; chars = "\\u001BT\\u001B[21~"; }
          { key = "Tab"; mods = "Control"; chars = "\\u001B)"; }
          { key = "Tab"; mods = "Control|Shift"; chars = "\\u001B("; }
          { key = "P"; mods = "Control|Shift"; chars = "\\u0002\\u001BOS"; } # C-b f4
        ];
      };
    };
  };
}
