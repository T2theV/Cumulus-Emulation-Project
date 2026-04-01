# default.nix
let
  nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/tarball/nixos-unstable";
  pkgs = import nixpkgs { config = {}; overlays = [(import ./pcsx2-overlay.nix)]; };
in
rec{
  pcsx2atts = builtins.fromJSON ( builtins.readFile ./pcsx2-full-out.json);
  pcsx2-src = pkgs.pcsx2.src.overrideAttrs(finalAttrs: previousAttrs: {
        hash = pcsx2atts.hash;
  });
  pcsx2-new = pkgs.pcsx2.overrideAttrs (finalAttrs: previousAttrs: {
      version = "99.99.99";
      src = pcsx2-src;
  });
}
