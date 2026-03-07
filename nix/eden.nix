# default.nix
let
  nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/tarball/nixos-unstable";
  pkgs = import nixpkgs { config = {}; overlays = [ (import ./eden-overlay.nix) ]; };
in
rec{
  #edenatts = builtins.fromJSON ( builtins.readFile ./eden-full-out.json);
  eden-src = pkgs.eden.src.overrideAttrs(finalAttrs: previousAttrs: { 
   hash = "sha256-rpb+bw0B8FGtN0Hxvr+cITxcXKukjvZOQ2SDqtoM5Gw=";
#edenatts.hash;
  });
  eden-new = pkgs.eden.overrideAttrs (finalAttrs: previousAttrs: {
      version = "master";
      src = eden-src;
      patches = [];
      nativeBuildInputs = [ pkgs.kdePackages.qtcharts ] ++ previousAttrs.nativeBuildInputs;
#      buildInputs = [ pkgs.qt6.full ] ++ previousAttrs.buildInputs;
  });
}
