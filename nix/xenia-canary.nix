let
  nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/tarball/nixos-unstable";
  pkgs = import nixpkgs { config = {}; overlays = []; };
in
rec{

  xeniaatts = builtins.fromJSON ( builtins.readFile ./xenia.json);
  xenia-new = pkgs.xenia-canary.overrideAttrs (finalAttrs: previousAttrs: {
      version = "master";
      src = pkgs.fetchFromGitHub {
        owner = xeniaatts.owner;
        repo = xeniaatts.repo;
        rev = xeniaatts.rev;
        hash = xeniaatts.hash;
        fetchSubmodules = true;
      };
    patches = [ ];
  });

}
