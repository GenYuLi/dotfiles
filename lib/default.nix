{ inputs, ... }:
let
  dotfiles = import ../config;
  lockfile = builtins.fromJSON (builtins.readFile ../flake.lock);
  input_name = lockfile.nodes.root.inputs.home-manager;

  inherit (inputs.nixpkgs) lib;

  nixpkgsOverlays = [
    # TODO: this should be local to system specific home-manager module, and loaded conditionally
    inputs.niri.overlays.niri
  ];

  nixpkgsConfig = {
    allowUnfree = true;
    allowUnfreePredicate = (_: true);
    packageOverrides = pkgs: {
      unstable = import inputs.nixpkgs-unstable {
        inherit (dotfiles) system;
        inherit (pkgs) config;
      };
    };
  };

  pkgs =
    # https://github.com/nix-community/home-manager/issues/2942#issuecomment-1378627909
    import inputs.nixpkgs {
      inherit (dotfiles) system;
      overlays = nixpkgsOverlays;
      config = nixpkgsConfig;
    };

  fontPkgs = with pkgs; [
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
    maple-mono.Normal-NF-CN-unhinted
    maple-mono.NF-CN-unhinted
  ] ++ (with nerd-fonts; [
    fira-code
    jetbrains-mono
    meslo-lg
    commit-mono
  ]);
in
{
  inherit dotfiles pkgs;

  stateVersion = "${builtins.elemAt (lib.splitString "-" lockfile.nodes.${input_name}.original.ref) 1}";

  mkHome = {}: {
    ${dotfiles.username} = inputs.home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      extraSpecialArgs = {
        inherit inputs dotfiles;
        isSystemConfig = false;
        nixgl = inputs.nixgl;
      };
      modules = [
        ../home
        ./nix.nix
        {
          fonts.fontconfig.enable = true;
          home.packages = fontPkgs;

          # Web/Electron apps (Heptabase, Notion, GitHub in Chrome, ...) list
          # macOS/Windows mono families first in their code-block CSS, e.g.
          #   font-family: SF Mono, Menlo, Consolas, ..., monospace
          # Goals:
          #   1. Latin renders as SF Mono (install via scripts/install-sf-mono.sh).
          #   2. CJK renders as Noto Sans Mono CJK TC — a mono CJK font that's
          #      visually close to PingFang (same Adobe/Google design lineage)
          #      and ships in fontPkgs above.
          # Without these rules, fontconfig substitutes unknown mono families
          # per-glyph: Latin → Liberation Mono, CJK → proportional Noto Sans
          # CJK TC. Two fonts, mismatched widths, ugly.
          xdg.configFile."fontconfig/conf.d/52-mac-win-mono-aliases.conf".text = ''
            <?xml version="1.0"?>
            <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
            <fontconfig>
              <!-- SF Mono itself: append CJK fallback so Chromium doesn't
                   pick proportional Noto Sans CJK for CJK glyphs. -->
              <alias binding="same">
                <family>SF Mono</family>
                <accept><family>Noto Sans Mono CJK TC</family></accept>
              </alias>

              <!-- Other macOS/Windows mono families that don't exist on Linux:
                   prefer SF Mono (installed via scripts/install-sf-mono.sh),
                   then the CJK fallback. -->
              <alias binding="same">
                <family>SFMono-Regular</family>
                <prefer><family>SF Mono</family></prefer>
                <accept><family>Noto Sans Mono CJK TC</family></accept>
              </alias>
              <alias binding="same">
                <family>ui-monospace</family>
                <prefer><family>SF Mono</family></prefer>
                <accept><family>Noto Sans Mono CJK TC</family></accept>
              </alias>
              <alias binding="same">
                <family>Menlo</family>
                <prefer><family>SF Mono</family></prefer>
                <accept><family>Noto Sans Mono CJK TC</family></accept>
              </alias>
              <alias binding="same">
                <family>Monaco</family>
                <prefer><family>SF Mono</family></prefer>
                <accept><family>Noto Sans Mono CJK TC</family></accept>
              </alias>
              <alias binding="same">
                <family>Consolas</family>
                <prefer><family>SF Mono</family></prefer>
                <accept><family>Noto Sans Mono CJK TC</family></accept>
              </alias>
              <alias binding="same">
                <family>Cascadia Code</family>
                <prefer><family>SF Mono</family></prefer>
                <accept><family>Noto Sans Mono CJK TC</family></accept>
              </alias>
              <alias binding="same">
                <family>Cascadia Mono</family>
                <prefer><family>SF Mono</family></prefer>
                <accept><family>Noto Sans Mono CJK TC</family></accept>
              </alias>
            </fontconfig>
          '';
        }
      ];
    };
  };

  mkSystem = { isDarwin }:
    let
      # NixOS vs nix-darwin functionst
      systemFunc = if isDarwin then inputs.darwin.lib.darwinSystem else inputs.nixpkgs.lib.nixosSystem;
      hmModules = if isDarwin then inputs.home-manager.darwinModules else inputs.home-manager.nixosModules;
    in
    {
      ${dotfiles.hostname} = systemFunc
        {
          specialArgs = { inherit inputs dotfiles; };
          modules = [
            ./nix.nix
            ../system/common
            ../system/${dotfiles.profile}
            hmModules.home-manager
            {
              fonts.packages = fontPkgs;
              nixpkgs.overlays = nixpkgsOverlays;
              nixpkgs.config = nixpkgsConfig;
            }
          ] ++ (pkgs.lib.optionals pkgs.stdenv.isDarwin [
            inputs.homebrew.darwinModules.nix-homebrew
          ]);
        };
    };
}
