let
  nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/tarball/nixos-unstable";
  pkgs = import nixpkgs { config = {}; overlays = []; };
in
rec{
  
  rpcs3atts = builtins.fromJSON ( builtins.readFile ./rpcs3.json);
  rpcs3-new = pkgs.rpcs3.overrideAttrs (finalAttrs: previousAttrs: {
      version = "master";
      src = pkgs.fetchFromGitHub {
        owner = "rpcs3";
        repo = "rpcs3";
        rev = rpcs3atts.rev;
        hash = rpcs3atts.hash;

        postCheckout = ''
          cd $out/3rdparty
          git submodule update --init \
            fusion/fusion asmjit/asmjit yaml-cpp/yaml-cpp SoundTouch/soundtouch stblib/stb \
            feralinteractive/feralinteractive protobuf
        '';

      };
      buildInputs = previousAttrs.buildInputs ++ [pkgs.protobuf];
      nativeBuildInputs = previousAttrs.nativeBuildInputs ++ [pkgs.protobuf];
  });

}