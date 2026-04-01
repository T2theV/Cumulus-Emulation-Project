# default.nix
let
  nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/tarball/nixos-unstable";
  pkgs = import nixpkgs { config = {}; overlays = [(import ./flycast-overlay.nix)]; };
in
rec {
  flycastatts = builtins.fromJSON ( builtins.readFile ./flycast-full-out.json);
  flycast-src = pkgs.flycast.src.overrideAttrs(finalAttrs: previousAttrs: {
    hash = flycastatts.hash;
  });
  flycast-new = pkgs.flycast.overrideAttrs (finalAttrs: previousAttrs: {
      version = "master";
      src = flycast-src;
  });
}
