# default.nix
let
  nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/tarball/nixos-25.11";
  pkgs = import nixpkgs { config = {}; overlays = []; };
in
rec{
  # dolatts = builtins.fromJSON ( builtins.readFile ./dol.json);
  dolphin-new = pkgs.dolphin-emu.overrideAttrs (finalAttrs: previousAttrs: {
      version = "master";
      src = pkgs.fetchFromGitHub {
        owner = "dolphin-emu";
        repo = "dolphin";
        rev = dolatts.rev;
        hash = dolatts.hash;
        fetchSubmodules = true;
        leaveDotGit = true;
      };
    preConfigure = "";
    patches = [ ];
  });
}
