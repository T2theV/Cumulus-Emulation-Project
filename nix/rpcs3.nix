let
  nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/tarball/nixos-25.11";
  pkgs = import nixpkgs { config = {}; overlays = []; };
in
rec{

  rpcs3atts = builtins.fromJSON ( builtins.readFile ./rpcs3.json);
  rpcs3-new = pkgs.rpcs3.overrideAttrs (finalAttrs: previousAttrs: {
      version = "master";
      src = pkgs.fetchFromGitHub {
        owner = rpcs3atts.owner;
        repo = rpcs3atts.repo;
        rev = rpcs3atts.rev;
        hash = rpcs3atts.hash;
        fetchSubmodules = true;
      };
    patches = [ ];
  });

}