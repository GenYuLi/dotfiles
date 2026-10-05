{ inputs, pkgs, lib, ... }:
let
  # https://github.com/Misterio77/nix-config/blob/8bb813869ea740fd7bcca1a033ecb53cc2bf77de/hosts/common/global/nix.nix#L7
  flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
in
{
  nix = {
    package = lib.mkDefault pkgs.nixVersions.latest;
    registry = lib.mapAttrs (_: flake: { inherit flake; }) flakeInputs;
    nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;

    gc = {
      automatic = true;
      options = "--delete-older-than 30d";
    };

    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      warn-dirty = false;
      # Apply a flake's nixConfig (this repo's cachix substituters) without the
      # per-run prompt / "Using saved setting" notice. Trade-off: any flake you
      # run can add substituters, since this user is trusted by the daemon.
      accept-flake-config = true;
      max-jobs = "auto";
      use-xdg-base-directories = true;
      auto-optimise-store = !pkgs.stdenv.isDarwin;

      # Only the daemon reads trusted-users. The nixos/darwin profiles write
      # this into /etc/nix/nix.conf; the home profile writes ~/.config/nix/nix.conf,
      # where it is ignored, so every restricted setting here (substituters,
      # trusted-public-keys, auto-optimise-store, use-xdg-base-directories) is
      # dropped with an "ignoring ... not a trusted user" warning. In that case
      # trust the user in the system config once, then restart the daemon (it
      # doesn't watch nix.conf: https://github.com/NixOS/nix/issues/8939):
      #   Linux: echo 'trusted-users = root @wheel' | sudo tee -a /etc/nix/nix.conf
      #          sudo systemctl restart nix-daemon
      #   macOS: echo 'trusted-users = root @admin' | sudo tee -a /etc/nix/nix.custom.conf
      #          sudo launchctl kickstart -k system/org.nixos.nix-daemon  # label: launchctl list | grep nix-daemon
      #          (Determinate installs include nix.custom.conf from nix.conf;
      #          plain installs: append to /etc/nix/nix.conf instead)
      # Verify with `nix store info --store daemon` -> "Trusted: 1".
      # macOS admin accounts are in `admin`, not `wheel`.
      trusted-users = [
        "root"
        (if pkgs.stdenv.isDarwin then "@admin" else "@wheel")
      ];
      extra-substituters = lib.mkAfter [
        "https://nix-community.cachix.org"
        "https://williamhsieh.cachix.org"
      ];
      extra-trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "williamhsieh.cachix.org-1:t3jW1IF+bHXN4Ce7ZZe9pLSjRB6D1gwz0EgGdgYxHNg="
      ];
    };
  };
}
