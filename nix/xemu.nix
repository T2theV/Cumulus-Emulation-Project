# default.nix
let
  nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/tarball/nixos-unstable";
  pkgs = import nixpkgs { config = {}; overlays = []; };
in
rec {
  #xemuatts = builtins.fromJSON ( builtins.readFile ./xemu.json);
  xemu-new = pkgs.xemu.overrideAttrs (finalAttrs: previousAttrs: {
      version = "99.99.99";
      src = pkgs.fetchFromGitHub {
        owner = "xemu-project";
        repo = "xemu";
        rev = "3b13aed14ce6350c0cbd7696799b041037c91ece";
        hash = "sha256-kTqg2Oo4bWyCkmcxAgE/bqCYAczPflKjwzrqveyG5H0=";

        nativeBuildInputs = [
          pkgs.git
          pkgs.meson
          pkgs.cacert
        ];
        # also fetch required git submodules
        postFetch = ''
          cd "$out"

          meson subprojects download \
            SPIRV-Reflect VulkanMemoryAllocator berkeley-softfloat-3 berkeley-testfloat-3 genconfig glslang imgui \
            implot json keycodemapdb nv2a_vsh_cpu tomlplusplus volk xxhash sdl3 || true
          find subprojects -type d -name .git -prune -execdir rm -r {} +
        '';
      };
      buildInputs = previousAttrs.buildInputs ++ [
        pkgs.cacert 
        pkgs.systemd 
        pkgs.pipewire 
        pkgs.libxkbcommon 
        pkgs.wayland-scanner
        ];
      nativeBuildInputs = previousAttrs.nativeBuildInputs ++ [pkgs.wayland-scanner];
  });
}