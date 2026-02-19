let
  nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/tarball/nixos-unstable";
  pkgs = import nixpkgs { config = {}; overlays = []; };
in
rec{

  # rmgatts = builtins.fromJSON ( builtins.readFile ./rmg.json);
  rmg-new = pkgs.rmg.overrideAttrs (finalAttrs: previousAttrs: {
      version = "master";
      src = pkgs.fetchFromGitHub {
        owner = "rosalie241";
        repo = "RMG";
        rev = "e9167db9ffbb16e10ac62a0a449dd6bfd124493a";
        hash = "";
        fetchSubmodules = true;
      };
    patches = [ ];
  });

}
