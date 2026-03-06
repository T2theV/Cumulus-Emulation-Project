# default.nix
let
  nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/tarball/nixos-unstable";
  pkgs = import nixpkgs { config = {}; overlays = []; };
in
rec {
  # xemuatts = builtins.fromJSON ( builtins.readFile ./xemu.json);
  xemu-new = pkgs.xemu.overrideAttrs (finalAttrs: previousAttrs: {
      version = "99.99.99";
      src = previousAttrs.src.overrideAttrs(finalAttrs: previousAttrs: {
        rev = "5aeacacfeb7a28ad7d5a9ecab9978115804148dc";
        hash = "sha256-oC44EMr71J6abDeGXtFAK68Ti/zi+CerxjFRALOoCwE=";
      });
      configureFlags = previousAttrs.configureFlags ++ [
          "--disable-opengl"
          "--enable-gtk"
      ];
      buildInputs = previousAttrs.buildInputs ++ [pkgs.pixman];
      nativeBuildInputs  = previousAttrs.nativeBuildInputs  ++ [pkgs.pixman];
  });
}