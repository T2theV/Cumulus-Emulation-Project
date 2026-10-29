# xenia-edge — has207/xenia-edge fork (branch `edge`), packaged following
# this repo's overlay convention (like the other emulators).
#
# Definition: ./xenia-edge.nix — fetchFromGitHub FOD with all 42 submodules,
# runtime data pinned in ./data-src.nix (which also needs ./src.nix), CMake
# patches in ./patches/.
#
# NOTE: deliberately NOT `prev.callPackage ./xenia-edge.nix {}` — the
# package's `src ? null` formal would be looked up on the whole pkgs
# attrset, and nixos-unstable (2026) has a sentinel that throws on
# `pkgs.src` (the `src` package was renamed to `simple-revision-control`).
# Explicit named args below sidestep that.
final: prev:
{
  xenia-edge = import ./xenia-edge.nix {
    inherit (prev) stdenv lib fetchFromGitHub;
    inherit (prev) clang cmake ninja pkg-config python3;
    inherit (prev) fmt zstd xxhash pugixml cxxopts tomlplusplus;
    inherit (prev) vulkan-loader zlib lz4 expat fontconfig libxkbcommon libGL
      alsa-lib pulseaudio dbus gtk3 xorg wayland glib cairo;
    inherit (prev) shader-slang sdl3;
    inherit (prev) snappy zarchive discord-rpc imgui miniaudio asio;
    inherit (prev) patchelf;
  };
}
