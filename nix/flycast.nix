# default.nix
let
  nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/tarball/nixos-unstable";
  pkgs = import nixpkgs { config = {}; overlays = []; };
in
{
  flycast-new = pkgs.flycast.overrideAttrs (finalAttrs: previousAttrs: {
      version = "master";
      src = pkgs.fetchFromGitHub {
        owner = "flyinghead";
        repo = "flycast";
        rev = "ba5b3c71ecc966e52f698f41443e7cc9b81bf824";
        hash = "sha256-tbq+NgbZDKMg0K0cWF1+7h80QTaAaO5BD9nf94z5fc0=";
        fetchSubmodules = true;
      };
      buildInputs = previousAttrs.buildInputs ++ [pkgs.systemd];
      cmakeFlags = previousAttrs.cmakeFlags ++ [ "-DUSE_OPENGL=OFF" ]
  });
}
