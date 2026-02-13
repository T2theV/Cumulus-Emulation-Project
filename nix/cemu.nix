let
  nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/tarball/nixos-unstable";
  pkgs = import nixpkgs { config = {}; overlays = []; };
in
rec{

  cemuatts = builtins.fromJSON ( builtins.readFile ./cemu.json);
  cemu-new = pkgs.cemu.overrideDerivation (oldAttrs: {
      version = "master";
      src = pkgs.fetchFromGitHub {
        owner = cemuatts.owner;
        repo = cemuatts.repo;
        rev = cemuatts.rev;
        hash = cemuatts.hash;
        fetchSubmodules = true;
      };
    patches = [ ];
  });

}
