let
  nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/tarball/nixos-unstable";
  pkgs = import nixpkgs { config = {}; overlays = [ (import ./rpcs3-overlay.nix) ]; };
in
rec{
  
  rpcs3atts = builtins.fromJSON ( builtins.readFile ./rpcs3-full-out.json);
  rpcs3-src = pkgs.rpcs3.src.overrideAttrs(finalAttrs: previousAttrs: {
    hash= rpcs3atts.hash;
  });
  rpcs3-new = pkgs.rpcs3.overrideAttrs (finalAttrs: previousAttrs: {
      version = "master";
      src = rpcs3-src;
      buildInputs = [ pkgs.protobuf ] ++ previousAttrs.buildInputs;
      cmakeFlags = [ (pkgs.lib.cmakeBool "USE_SYSTEM_PROTOBUF" true) ] ++ previousAttrs.cmakeFlags;
  });

}