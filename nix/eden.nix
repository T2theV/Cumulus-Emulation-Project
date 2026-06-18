# default.nix
let
  nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/tarball/nixos-unstable";
  pkgs = import nixpkgs { config = {}; overlays = [ (import ./eden-overlay.nix) ]; };
in
rec{
  #edenatts = builtins.fromJSON ( builtins.readFile ./eden-full-out.json);
  eden-src = pkgs.eden.src.overrideAttrs(finalAttrs: previousAttrs: { 
   hash = "sha256-YljgWKS12iOXFo8CI43dYsJtLsxyy9MjxQrNHK1Dxh0=";
#edenatts.hash;
  });
  eden-new = pkgs.eden.overrideAttrs (finalAttrs: previousAttrs: {
      version = "master";
      src = eden-src;
      patches = [];
      nativeBuildInputs = [ pkgs.kdePackages.qtcharts
			    pkgs.sdl3
			 ] ++ previousAttrs.nativeBuildInputs;
      buildInputs = [ pkgs.sdl3 ] ++ previousAttrs.buildInputs;
      postInstall = "";
  });
}
