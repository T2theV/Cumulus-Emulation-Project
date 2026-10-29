# Nix source (FOD) definition for has207/xenia-edge @ edge branch.
# Hash computed via nix's dummy-hash mismatch, then verified with nix-build.
let p = import <nixpkgs> {};
in p.fetchFromGitHub {
  owner = "has207";
  repo = "xenia-edge";
  rev = "f466500c3bec97ac0a070f183ecc27d30ef40579";
  fetchSubmodules = true;
  sha256 = "rU+y/PSA6iMPsQAjyali31D/vyL+Bm0j9+czGrrdFmg=";
}
