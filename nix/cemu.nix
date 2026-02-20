# default.nix
let
  nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/tarball/nixos-unstable";
  pkgs = import nixpkgs { config = {}; overlays = []; };
in
{
  #cemuatts = builtins.fromJSON ( builtins.readFile ./cemu.json);
  cemu-new = pkgs.cemu.overrideAttrs (finalAttrs: previousAttrs: {
      version = "99.99";
       src = pkgs.fetchFromGitHub {
        owner = "cemu-project";
        repo = "Cemu";
        rev = "3b5c6f5246e1e94bda623f618f71a37de22578b3";
        hash = "sha256-b/mqd/OwJiyoUG59gZ1+LFVXQP+hwkHNx04Spz+2jn4=";
      };
      patches = [
        "/work/imgui.patch"
      ];
      buildInputs = previousAttrs.buildInputs ++ [
        pkgs.wxwidgets_3_3
      ];
      nativeBuildInputs = [
        pkgs.wxwidgets_3_3
      ] ++ previousAttrs.nativeBuildInputs;
  });
}