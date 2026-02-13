# default.nix
let
  nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/tarball/nixos-unstable";
  pkgs = import nixpkgs { config = {}; overlays = []; };
in
rec {
  xemuLocal = pkgs.callPackage ./xemu-pkg.nix { };
  xemuatts = builtins.fromJSON ( builtins.readFile ./xemu.json);
  xemu-new = xemuLocal.overrideDerivation (oldAttrs: {
      version = "master";
      src = pkgs.fetchFromGitHub {
        owner = xemuatts.owner;
        repo = xemuatts.repo;
        rev = xemuatts.rev;
        hash = xemuatts.hash;
        fetchSubmodules = true;
      };
  });
}