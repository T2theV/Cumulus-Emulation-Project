# default.nix
let
  nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/tarball/nixos-unstable";
  pkgs = import nixpkgs { config = {}; overlays = []; };
in
rec{
  pcsx2atts = builtins.fromJSON ( builtins.readFile ./pcsx2.json);
  pcsx2-new = pkgs.pcsx2.overrideDerivation (oldAttrs: {
      version = "master";
      src = pkgs.fetchFromGitHub {
        owner = pcsx2atts.owner;
        repo = pcsx2atts.repo;
        rev = pcsx2atts.rev;
        hash = pcsx2atts.hash;
      };
  });
}
