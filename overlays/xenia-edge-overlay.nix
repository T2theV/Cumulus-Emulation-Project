# xenia-edge — has207/xenia-edge fork (branch `edge`), packaged following
# this repo's overlay convention (like the other emulators).
#
# Definition: ./xenia-edge.nix — source from ./src.nix (superproject + the
# 21 submodules the build uses, grafted), runtime data pinned in
# ./data-src.nix (which also needs ./src.nix), CMake patches in ./patches/.
#
# Mutable runtime data: the compatibility_data.json the build embeds is a
# GitHub release asset behind a MUTABLE tag (xenia-canary/game-compatibility);
# upstream re-publishes it, so a hardcoded sha256 rots. fetch-compat-hash.sh
# (run by localbuild.sh) queries the GitHub API for the asset's sha256 and
# writes ./xenia-compat-data-hash.json. We read it here and pass it in as the
# optional `compatibilityData` formal (a fetchurl), re-pinning the live hash.
# If the JSON is absent (fetch failed / offline / skipped), we pass null and
# the build proceeds without the compatibility database.
#
# NOTE: explicit call, not `prev.callPackage ./xenia-edge.nix {}` — stdenv
# must be prev.clangStdenv (the CC wrapper exporting CC/CXX=clang);
# callPackage would hand over the gcc stdenv.
final: prev:
let
  # The live compatibility_data.json hash, written by fetch-compat-hash.sh.
  # A fetchurl (with the live sha256) when the JSON is present, else null so
  # the build still works without the compatibility DB.
  compatibilityData = if builtins.pathExists ./xenia-compat-data-hash.json then
    let c = builtins.fromJSON (builtins.readFile ./xenia-compat-data-hash.json);
    in prev.fetchurl { url = c.url; sha256 = c.hash; }
  else null;
in {
  xenia-edge = import ../emus/xenia-edge/xenia-edge.nix {
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
    # Mutable compatibility_data.json, re-pinned from the live hash (or null
    # to build without it — see data-src.nix / fetch-compat-hash.sh).
    compatibilityData = compatibilityData;
  };
}
