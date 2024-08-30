{ pkgs, lib, ... }:
{
  programs.alacritty = {
    enable = true;
    settings = {
      shell = {
        program = "${pkgs.zsh}/bin/zsh";
      };
      env = {
        TERM = "xterm-256color";
        LANG = "C.UTF-8";
        CC = "gcc";
      };
      font = {
        normal.family = "MesloLGMDZ Nerd Font Mono";
        size = 10.5;
      };
      window = {
        dynamic_padding = true;
        option_as_alt = "Both";
      };
      colors = {
        indexed_colors = [
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
