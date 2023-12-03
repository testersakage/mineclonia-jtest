let
  pkgs = import <nixpkgs> {}; # fetchTarball "https://github.com/NixOS/nixpkgs/tarball/nixos-23.11";
in

pkgs.mkShell {
  packages = with pkgs; [
    luaPackages.busted
    luaPackages.luacheck
  ];
}
