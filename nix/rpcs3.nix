let
  nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/tarball/nixos-unstable";
  pkgs = import nixpkgs { config = {}; overlays = []; };
in
rec{
  
  # rpcs3atts = builtins.fromJSON ( builtins.readFile ./rpcs3.json);
  rpcs3-new = pkgs.rpcs3.overrideAttrs (finalAttrs: previousAttrs: {
      version = "master";
      src = pkgs.fetchFromGitHub {
        owner = "rpcs3";
        repo = "rpcs3";
        rev = "2064bd87e37da1d0946f7c5b62f2d38003abff8e";
        hash = "";

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