# default.nix
let
  nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/tarball/nixos-unstable";
  pkgs = import nixpkgs { config = {}; overlays = []; };
in
rec{
  #pcsx2atts = builtins.fromJSON ( builtins.readFile ./pcsx2.json);
  pcsx2-new = pkgs.pcsx2.overrideAttrs (finalAttrs: previousAttrs: {
      version = "99.99.99";
      src = pkgs.fetchFromGitHub {
        owner = "pcsx2";
        repo = "pcsx2";
        rev = "b7fa45ee76bb47e02ce78ebd674d3dd46d519689";
        hash = "sha256-XLiN3iIc/fi0OJM1Ip0tfSShGVQunuJjpdeH5zlX8WM=";
      };
    postPatch = "";
  });
}
