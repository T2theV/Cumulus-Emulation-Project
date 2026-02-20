let
  nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/tarball/nixos-unstable";
  pkgs = import nixpkgs { config = {}; overlays = []; };
in
rec{

  # xeniaatts = builtins.fromJSON ( builtins.readFile ./xenia.json);
  xenia-new = pkgs.xenia-canary.overrideAttrs (finalAttrs: previousAttrs: {
      version = "master";
      src = pkgs.fetchFromGitHub {
        owner = "xenia-canary";
        repo = "xenia-canary";
        fetchSubmodules = true;
        rev = "bc69b95db698efdcb4dcf36101b9c252d28f0c95";
        hash = "sha256-0jflmjEtY2RuJSaiCPTlhWCS0bQDMp9ZyILxmUxLvzk=";
      };
    buildInputs = [pkgs.alsa-lib] ++ previousAttrs.buildInputs;
  });
}
