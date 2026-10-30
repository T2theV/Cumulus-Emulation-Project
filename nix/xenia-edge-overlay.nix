# xenia-edge — has207/xenia-edge fork (branch `edge`), packaged following
# this repo's overlay convention (like the other emulators).
#
# Definition: ./xenia-edge.nix — source from ./src.nix (superproject + the
# 21 submodules the build uses, grafted), runtime data pinned in
# ./data-src.nix (which also needs ./src.nix), CMake patches in ./patches/.
#
# NOTE: explicit call, not `prev.callPackage ./xenia-edge.nix {}` — stdenv
# must be prev.clangStdenv (the CC wrapper exporting CC/CXX=clang);
# callPackage would hand over the gcc stdenv.
final: prev:
{
  xenia-edge = import ./xenia-edge.nix {
    # clang toolchain: clangStdenv so the CC wrapper exports CC/CXX=clang
    # for the whole build (clang is no longer a package formal).
    stdenv = prev.clangStdenv;
    inherit (prev) lib;
    inherit (prev) cmake ninja pkg-config python3;
    inherit (prev) fmt zstd xxhash pugixml cxxopts tomlplusplus;
    inherit (prev) vulkan-loader zlib lz4 expat fontconfig libxkbcommon libGL
      alsa-lib pulseaudio dbus gtk3 xorg wayland glib cairo;
    inherit (prev) shader-slang sdl3;
    inherit (prev) snappy zarchive discord-rpc imgui miniaudio asio;
    inherit (prev) patchelf;
  };
}
