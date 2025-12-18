# default.nix
let
  nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/tarball/nixos-25.11";
  pkgs = import nixpkgs { config = {}; overlays = []; };
in
rec{
  dolatts = builtins.fromJSON ( builtins.readFile ./dol.json);
  dolphin-new = pkgs.dolphin-emu.overrideAttrs (finalAttrs: previousAttrs: {
      version = "master";
      src = pkgs.fetchFromGitHub {
        owner = dolatts.owner;
        repo = dolatts.repo;
        rev = dolatts.rev;
        hash = dolatts.hash;
        fetchSubmodules = true;
        leaveDotGit = true;
      };
    preConfigure = "";
    patches = [ ];
  });

  rpcs3-new = pkgs.rpcs3.overrideAttrs (finalAttrs: previousAttrs: {
    version = "master";
    src = pkgs.fetchFromGitHub {
      owner = "RPCS3";
      repo = "rpcs3";
      rev = "cf87f24587754cd3869430d0df6d396985db3165";
      hash = "sha256-GiuGYk9OzGWVoEyIEVLaNY/fIM+7L5N2zjXGDgpt5vE=";
      fetchSubmodules = true;
    };
    patches = [ ];
   });
}