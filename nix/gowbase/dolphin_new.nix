# default.nix
let
  nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/tarball/nixos-unstable";
  pkgs = import nixpkgs { config = {}; overlays = []; };
in
rec{
  # dolatts = builtins.fromJSON ( builtins.readFile ./dol.json);
  dolphin-src = pkgs.dolphin-emu.src.overrideAttrs (finalAttrs: previousAttrs: {
        tag = 0;
        rev = "d58e7ca9325217574d84d961b824e0acbf2f67e9";
        hash = pkgs.lib.fakeHash;
        #"sha256-i13c+ccwgkVgXfSRAtaZvh7lz+FvNiFbWzenvOc/V/A=";
  });
  dolphin-new = pkgs.dolphin-emu.overrideAttrs (finalAttrs: previousAttrs: {
      version = "master";
      src = dolphin-src;
  });
}
