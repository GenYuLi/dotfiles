{ pkgs, lib, ... }:
{
  # macOS: install via Homebrew cask (nixpkgs ghostty only supports Linux)
  home.packages = lib.optionals pkgs.stdenv.isLinux [
    pkgs.unstable.ghostty
  ];

  home.file.".config/ghostty/config".text = ''
    # Shell
    command = ${pkgs.zsh}/bin/zsh

    # Font
    font-family = Maple Mono Normal NF CN
    font-size = 16.5
    font-feature = +liga
    font-feature = +calt

    # Theme - catppuccin mocha (matches alacritty)
    theme = catppuccin-mocha
    background-opacity = 1.0
    # background-opacity = 0.95
    # background-blur-radius = 20
    # unfocused-split-opacity = 0.9

    # Window
    window-decoration = true
    window-padding-x = 8
    window-padding-y = 8
    window-padding-balance = true

    # macOS
    macos-option-as-alt = true
    macos-titlebar-style = tabs

    # Cursor
    cursor-style = block
    cursor-style-blink = false

    # Shell integration
    # features: cursor tracking, sudo highlight, dynamic title, ssh TERM compat
    shell-integration = detect
    shell-integration-features = cursor,sudo,title,ssh-env

    # Clipboard
    copy-on-select = false
    clipboard-read = allow
    clipboard-write = allow
    clipboard-trim-trailing-spaces = true

    # Mouse
    mouse-hide-while-typing = true

    # Keybindings - aligned with alacritty
    keybind = ctrl+shift+c=copy_to_clipboard
    keybind = ctrl+shift+v=paste_from_clipboard
    keybind = ctrl+shift+n=new_window
    keybind = ctrl+shift+w=close_surface

    # tmux session management (matches alacritty bindings)
    keybind = ctrl+shift+t=text:\u001BT
    keybind = ctrl+tab=text:\u001B)
    keybind = ctrl+shift+tab=text:\u001B(

    # tmux pane split (sends prefix + \ or -)
    keybind = ctrl+shift+d=text:\u0002\\
    keybind = ctrl+shift+e=text:\u0002-

    # tmux pane navigation - Alt+Shift+Arrow (sends \e[1;4D/C/A/B = M-S-Arrow)
    keybind = alt+shift+arrow_left=text:\u001B[1;4D
    keybind = alt+shift+arrow_right=text:\u001B[1;4C
    keybind = alt+shift+arrow_up=text:\u001B[1;4A
    keybind = alt+shift+arrow_down=text:\u001B[1;4B

    # Font size
    keybind = ctrl+plus=increase_font_size:1
    keybind = ctrl+minus=decrease_font_size:1
    keybind = ctrl+zero=reset_font_size

    # Scrollback
    scrollback-limit = 10000

    # Disable auto-update (managed by Nix/Homebrew)
    auto-update = off
  '';
}
