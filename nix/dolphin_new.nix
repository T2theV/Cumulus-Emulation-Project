# default.nix
let
  nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/tarball/nixos-unstable";
  pkgs = import nixpkgs { config = {}; overlays = []; };
in
rec{
  # dolatts = builtins.fromJSON ( builtins.readFile ./dol.json);
  dolphin-src = pkgs.dolphin-emu.src.overrideAttrs (finalAttrs: previousAttrs: {
        tag = 0;
        rev = "9323074ada4b1d372809dc71ed092efe8d0e4c8e";
        hash = pkgs.lib.fakeHash;
        #"sha256-i13c+ccwgkVgXfSRAtaZvh7lz+FvNiFbWzenvOc/V/A=";
  });
  dolphin-new = pkgs.dolphin-emu.overrideAttrs (finalAttrs: previousAttrs: {
      version = "master";
      src = dolphin-src;
  });
}
