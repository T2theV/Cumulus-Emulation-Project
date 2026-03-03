let
  nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/tarball/nixos-unstable";
  pkgs = import nixpkgs { config = {}; overlays = []; };
  topsrc = import ./topsrc.nix;
in
rec{
  
  rpcs3atts = builtins.fromJSON ( builtins.readFile ./rpcs3-full-out.json);
  rpcs3-src = pkgs.rpcs3.src.overrideAttrs(finalAttrs: previousAttrs: {
    tag=0; 
    rev=rpcs3atts.rev;
    hash= rpcs3atts.hash;
    postCheckout = topsrc.postCheckout;
  });
  rpcs3-new = pkgs.rpcs3.overrideAttrs (finalAttrs: previousAttrs: {
      version = "master";
      src = rpcs3-src;
  });

}