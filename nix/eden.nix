# default.nix
let
  nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/tarball/nixos-unstable";
  pkgs = import nixpkgs { config = {}; overlays = [ (import ./eden-overlay.nix) ]; };
in
rec{
  edenatts = builtins.fromJSON ( builtins.readFile ./eden-full-out.json);
  eden-src = pkgs.eden.src.overrideAttrs(finalAttrs: previousAttrs: { 
   hash = edenatts.hash;
  });
  eden-new = pkgs.eden.overrideAttrs (finalAttrs: previousAttrs: {
      version = "master";
      src = eden-src;
      nativeBuildInputs = [ pkgs.kdePackages.qtcharts
			    pkgs.sdl3
			 ] ++ previousAttrs.nativeBuildInputs;
      buildInputs = [ pkgs.sdl3 ] ++ previousAttrs.buildInputs;
      postInstall = "";
      postConfigure = "";
  });
}
