let
  nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/tarball/nixos-unstable";
  pkgs = import nixpkgs { config = {}; overlays = [(import ./rmg-overlay.nix)]; };
in
rec{

  rmgatts = builtins.fromJSON ( builtins.readFile ./rmg-full-out.json);
  rmg-src = pkgs.rmg.src.overrideAttrs(finalAttrs: previousAttrs: {
        hash = rmgatts.hash;
  });
  rmg-new = pkgs.rmg.overrideAttrs (finalAttrs: previousAttrs: {
      version = "master";
      src = rmg-src;
  });

}
