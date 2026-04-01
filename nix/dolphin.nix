# default.nix
let
  nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/tarball/nixos-unstable";
  pkgs = import nixpkgs { config = {}; overlays = [ (import ./dolphin-emu-overlay.nix) ]; };
in
rec{
  dolphinatts = builtins.fromJSON ( builtins.readFile ./dolphin-emu-full-out.json);
  dolphin-src = pkgs.dolphin-emu.src.overrideAttrs(finalAttrs: previousAttrs: {
    hash = dolphinatts.hash;
  });
  dolphin-new = pkgs.dolphin-emu.overrideAttrs (finalAttrs: previousAttrs: {
      version = "master";
      src = dolphin-src;
  });
}
