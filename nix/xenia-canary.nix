let
  nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/tarball/nixos-unstable";
  pkgs = import nixpkgs { config = {}; overlays = [(import ./xenia-canary-overlay.nix)]; };
in
rec{

  xeniaatts = builtins.fromJSON ( builtins.readFile ./xenia-canary-full-out.json);
  xc-src = pkgs.xenia-canary.src.overrideAttrs(finalAttrs: previousAttrs {
    hash = xeniaatts.hash;
  });
  xenia-new = pkgs.xenia-canary.overrideAttrs (finalAttrs: previousAttrs: {
      version = "master";
      src = xeniaatts.hash
  });
}
