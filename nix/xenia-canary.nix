let
  nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/tarball/nixos-unstable";
  pkgs = import nixpkgs { config = {}; overlays = []; };
in
rec{

  xenia-canaryLocal = pkgs.callPackage ./xenia-canary-pkg.nix { };
  xeniaatts = builtins.fromJSON ( builtins.readFile ./xenia.json);
  xenia-new = xenia-canaryLocal.overrideDerivation (oldAttrs: {
      version = "master";
      src = pkgs.fetchFromGitHub {
        owner = xeniaatts.owner;
        repo = xeniaatts.repo;
        rev = xeniaatts.rev;
        hash = xeniaatts.hash;
        fetchSubmodules = true;
      };
  });

}
