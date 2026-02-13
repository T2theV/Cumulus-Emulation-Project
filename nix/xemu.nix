let
  nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/tarball/nixos-unstable";
  pkgs = import nixpkgs { config = {}; overlays = []; };
in
rec{

  xemuatts = builtins.fromJSON ( builtins.readFile ./xemu.json);
  xemu-new = pkgs.xemu.overrideAttrs (finalAttrs: previousAttrs: {
      version = "master";
      src = pkgs.fetchFromGitHub {
        owner = xemuatts.owner;
        repo = xemuatts.repo;
        rev = xemuatts.rev;
        hash = xemuatts.hash;
        fetchSubmodules = true;
      };
    patches = [ ];
  });

}
