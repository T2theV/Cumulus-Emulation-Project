# default.nix
let
  nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/tarball/nixos-unstable";
  pkgs = import nixpkgs { config = {}; overlays = []; };
in
rec {
  cemuLocal = pkgs.callPackage ./cemu-pkg.nix { };
  cemuatts = builtins.fromJSON ( builtins.readFile ./cemu.json);
  cemu-new = cemuLocal.overrideDerivation (oldAttrs: {
      version = "master";
      src = pkgs.fetchFromGitHub {
        owner = cemuatts.owner;
        repo = cemuatts.repo;
        rev = cemuatts.rev;
        hash = cemuatts.hash;
        fetchSubmodules = true;
      };
  });
}