{
  home = {
    system = "x86_64-linux";
    username = "witherslin";
    fullname = "witherslin";
    email = "witherslin@synology.com";
    dotDir = "dotfiles"; # path relative to $HOME, this example represents `~/dotfiles`
    wsl = false;
    gui = false;
  };

  nixos = {
    system = "x86_64-linux";
    hostname = "nixos-local";
  };

  darwin = {
    system = "aarch64-darwin";
    hostname = "macos-local";
  };
}
