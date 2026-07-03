{ lib, pkgs, config, dotfiles, ... }:
let
  link = path: config.lib.file.mkOutOfStoreSymlink "${dotfiles.directory}/config/${path}";
  yamlFormat = pkgs.formats.yaml { };
  clangdConfig = "clangd/config.yaml";
in
{
  home.packages = with pkgs; [
    gcc
    gnumake
    ninja
    # clangd/clang-format from a current LLVM (clang 19+): Apple's clangd 16
    # can't parse C++23 deducing-this ("this auto&& self"). On PATH before
    # /usr/bin, so `clangd`/`clang-format` resolve here.
    clang-tools
  ] ++ (pkgs.lib.optionals pkgs.stdenv.isLinux [
    gdb
    mold
  ]);

  xdg.configFile = {
    # https://clangd.llvm.org/config.html
    ${clangdConfig}.source = yamlFormat.generate "config.yaml" {
      CompileFlags = {
        Add = [ "-Wall" "-Wextra" "-Wshadow" "-std=c++23" ]
          # Apple clangd (arm64) rejects __float128, but GCC 14's arm64 stddef.h
          # puts a __float128 member into max_align_t under (__APPLE__ && __aarch64__).
          # Redefine it to a type Apple clang accepts so clangd can parse GCC's
          # libstdc++ (e.g. <bits/stdc++.h>). clangd-only — real g++ builds, which
          # do support __float128, are unaffected.
          ++ lib.optionals pkgs.stdenv.isDarwin [ "-D__float128=long double" ];
        Compiler = "${pkgs.gcc}/bin/g++";
      };
    };
  };

  # https://clangd.llvm.org/config#files
  home.activation = lib.optionalAttrs pkgs.stdenv.isDarwin {
    linkClangdConfigPath = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      ln -sfn ${config.xdg.configHome}/clangd ${config.home.homeDirectory}/Library/Preferences/clangd
    '';
  };

  home.file = {
    ".clang-format".source = link "clangd/.clang-format";
  };
}
