# default.nix
let
  nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/tarball/nixos-unstable";
  pkgs = import nixpkgs { config = {}; overlays = []; };
in
rec {
  # xemuatts = builtins.fromJSON ( builtins.readFile ./xemu.json);
  xemu-new = pkgs.xemu.overrideAttrs (finalAttrs: previousAttrs: {
      version = "99.99.99";
      src = pkgs.fetchFromGitHub {
        owner = "xemu-project";
        repo = "xemu";
        rev = "5aeacacfeb7a28ad7d5a9ecab9978115804148dc";
        hash = "";

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