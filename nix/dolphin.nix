# default.nix
let
  nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/tarball/nixos-unstable";
  pkgs = import nixpkgs { config = {}; overlays = []; };
in
rec{
  # dolatts = builtins.fromJSON ( builtins.readFile ./dol.json);
  dolphin-new = pkgs.dolphin-emu.overrideAttrs (finalAttrs: previousAttrs: {
      version = "master";
      src = pkgs.fetchFromGitHub {
        owner = "dolphin-emu";
        repo = "dolphin";
        rev = "9323074ada4b1d372809dc71ed092efe8d0e4c8e";
        hash = "sha256-i13c+ccwgkVgXfSRAtaZvh7lz+FvNiFbWzenvOc/V/A=";
        fetchSubmodules = true;
        leaveDotGit = true;
        postFetch = ''
          pushd $out
          git rev-parse HEAD 2>/dev/null >$out/COMMIT
          find $out -name .git -print0 | xargs -0 rm -rf
          popd
        '';
      };
  });
}
