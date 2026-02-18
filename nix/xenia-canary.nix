let
  nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/tarball/nixos-unstable";
  pkgs = import nixpkgs { config = {}; overlays = []; };
in
{

  
  #xeniaatts = builtins.fromJSON ( builtins.readFile ./xenia.json);
  xenia-new = pkgs.xenia-canary.overrideAttrs (finalAttrs: previousAttrs: {
      version = "master";
      src = pkgs.fetchFromGitHub {
        owner = "xenia-canary";
        repo = "xenia-canary";
        fetchSubmodules = true;
        rev = "07501cfcb9f592c3f99eeb7a8d8f10294755a980";
        hash = "sha256-dacGpGAK4At0KXdANY6ibEAjxWcY4bUbyFraXO+kK/0=";
      };
  });

}
