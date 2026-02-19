# default.nix
let
  nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/tarball/nixos-unstable";
  pkgs = import nixpkgs { config = {}; overlays = []; };
in
rec {
  flycastatts = builtins.fromJSON ( builtins.readFile ./flycast.json);
  flycast-new = pkgs.flycast.overrideAttrs (finalAttrs: previousAttrs: {
      version = "master";
      src = pkgs.fetchFromGitHub {
        owner = "flyinghead";
        repo = "flycast";
        rev = "ba5b3c71ecc966e52f698f41443e7cc9b81bf824";
        hash = "";
        fetchSubmodules = true;
      };
      buildInputs = previousAttrs.buildInputs ++ [pkgs.systemd];
      cmakeFlags = previousAttrs.cmakeFlags ++ [ "-DUSE_OPENGL=OFF" ];
  });
}
