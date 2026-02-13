let
  nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/tarball/nixos-unstable";
  pkgs = import nixpkgs { config = {}; overlays = []; };
in
rec{

  rmgatts = builtins.fromJSON ( builtins.readFile ./rmg.json);
  rmg-new = pkgs.rmg.overrideAttrs (finalAttrs: previousAttrs: {
      version = "master";
      src = pkgs.fetchFromGitHub {
        owner = rmgatts.owner;
        repo = rmgatts.repo;
        rev = rmgatts.rev;
        hash = rmgatts.hash;
        fetchSubmodules = true;
      };
    patches = [ ];
  });

}
