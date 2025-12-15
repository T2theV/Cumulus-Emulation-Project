# default.nix
let
  nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/tarball/nixos-25.11";
  pkgs = import nixpkgs { config = {}; overlays = []; };
in
rec{
  # dolphin = pkgs.callPackage ./dolphin.nix { };
  dolphin-new = pkgs.dolphin-emu.overrideAttrs (finalAttrs: previousAttrs: {
      version = "master";
      src = pkgs.fetchFromGitHub {
      owner = "dolphin-emu";
      repo = "dolphin";
      rev = "04f71e5e6d6b7fd3736b8b1f60f7970b34ec1e3f";
      hash = "sha256-hfiB2RxWqe4sQoMrG08CcKfhenARwiDUtARe2ew3/DU=";
      fetchSubmodules = true;
      leaveDotGit = true;
      postFetch = ''
        pushd $out
        git rev-parse HEAD 2>/dev/null >$out/COMMIT
        find $out -name .git -print0 | xargs -0 rm -rf
        popd
      '';
    };
    patches = [ ];
  });
}