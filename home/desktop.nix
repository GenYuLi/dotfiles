# Desktop theming for KDE Plasma on Fedora (standalone Home Manager on Linux)
# Qt/Kvantum and cursor are auto-themed via global catppuccin.enable
# GTK theme is handled by KDE Global Theme (catppuccin/nix removed gtk module in 25.05)
{ pkgs, lib, dotfiles, ... }:
lib.mkIf (pkgs.stdenv.isLinux && dotfiles.profile == "home") {
  qt = {
    enable = true;
    platformTheme.name = "kvantum";
    style.name = "kvantum";
  };

  catppuccin.cursors.enable = true;

  home.pointerCursor = {
    enable = true;
    size = 24;
    gtk.enable = true;
    x11.enable = true;
  };
}
