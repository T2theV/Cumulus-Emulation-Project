# default.nix
let
  nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/tarball/nixos-unstable";
  pkgs = import nixpkgs { config = {}; overlays = []; };
in
rec {
  flycastLocal = pkgs.callPackage ./flycast-pkg.nix { };
  flycastatts = builtins.fromJSON ( builtins.readFile ./flycast.json);
  flycast-new = flycastLocal.overrideDerivation (oldAttrs: {
      version = "master";
      src = pkgs.fetchFromGitHub {
        owner = flycastatts.owner;
        repo = flycastatts.repo;
        rev = flycastatts.rev;
        hash = flycastatts.hash;
        fetchSubmodules = true;
      };
  });
}
