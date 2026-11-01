# xenia-edge.nix — nixpkgs-style package for the has207/xenia-edge fork (branch: edge).
#
# Source: ./src.nix — the pinned superproject plus the 34 submodules the
# x86_64 Linux build actually consumes, grafted (see that file for the
# keep/drop split and re-pinning notes). Runtime data: ./data-src.nix.
#
# nixpkgs-style usage:
#   xenia-edge = import ./xenia-edge.nix { stdenv = prev.clangStdenv; … };
# (see xenia-edge-overlay.nix / eval-fod.nix for the full call).

{ stdenv
, lib

, cmake
, ninja
, pkg-config
, python3

, fmt
, zstd
, xxhash
, pugixml
, cxxopts
, tomlplusplus

, snappy
, zarchive
, discord-rpc
, imgui
, miniaudio
, asio

, vulkan-loader
, zlib
, lz4
, expat
, fontconfig
, libxkbcommon
, libGL
, alsa-lib
, pulseaudio
, dbus
, gtk3
, xorg
, wayland
, glib
, cairo

, shader-slang
, sdl3

, patchelf
}:

let
  # Libraries switched from vendored third_party to nixpkgs system packages
  # (see patches/xenia-edge-cmake.diff). sdl3 is an output attrset (no plain
  # .outPath), so its outputs are listed directly: lib carries the runtime
  # libSDL3.so.0 (linked and dlopen'd by system_gnulinux.cc), dev carries
  # headers + the CMake config consumed by find_package(SDL3). The others
  # are plain packages; the extra dev/lib outputs they need for headers or
  # the prebuilt library are appended to CMAKE_PREFIX_PATH below.
  # zlib-ng is intentionally NOT here: the in-tree vendored third_party/zlib-ng
  # submodule is built (the diff keeps that section untouched), so no nixpkgs
  # zlib-ng is needed at build or link time.
  libs = [ fmt zstd xxhash pugixml cxxopts tomlplusplus
    snappy zarchive discord-rpc imgui miniaudio asio
    sdl3.lib sdl3.dev ];

  # System dependencies the build links against (mirrors the verified
  # devShell in devshell.nix).
  deps = [
    vulkan-loader zlib lz4 expat fontconfig libxkbcommon libGL
    alsa-lib pulseaudio dbus gtk3
    xorg.libX11 xorg.libXext xorg.libXrandr xorg.libXinerama
    xorg.libXcursor xorg.libXi xorg.libXfixes xorg.libXtst
  ];

  # wayland: wayland-client.pc, linked by src/xenia/ui (see patch).
  # glib/cairo: provide the glib-2.0 / cairo .pc files in the Requires
  # chain of gtk+-x11-3.0 (not otherwise a direct build input).
  # shader-slang: provides bin/slangc (replaces the vendored slang build).
  all = libs ++ deps ++ [ wayland glib cairo shader-slang ];

  # .pc modules that nixpkgs does not ship a .pc file under these names.
  # The vendored wxWidgets/FFmpeg CMake only probes for their presence
  # (version checks); real headers/libs come from the buildInputs above or
  # from vendored sources. Generated in preBuild; identical to the
  # /root/pc-stubs/ tree used by the verified nix-shell build.
  stubModules = [
    "Lerc" "at-spi2-atk" "at-spi2-core" "at-spi2-registryd"
    "cairo-freetype" "cairo-pango" "dconf" "dconf-gsettings" "epoxy" "glu"
    "gsettings" "libGL" "libdatrie" "libdbus" "libharfbuzz" "liblzma"
    "libmount" "libpcre2-8" "libselinux" "libsepol" "libsystemd" "libthai"
    "mount" "pango-1.0" "pangoxft2" "sysprof-capture-4" "systemd"
    "xcb-proto" "xdmcp" "zstd"
  ];

  # Runtime data (game patches, game DB, controller DB, compatibility
  # data) pinned in ./data-src.nix; baked into $SRC_DIR/build/data_repos
  # in configurePhase, replacing xenia-build.py's fetch_data_repos().
  dataRepos = (import ./data-src.nix).data-repos;
in
stdenv.mkDerivation rec {
  pname = "xenia-edge";
  version = "f466500c3";

  # Grafted source: superproject + the 34 submodules the build uses
  # (see ./src.nix).
  src = (import ./src.nix).src;

  patches = [
    ./patches/xenia-edge-cmake.diff
    ./patches/wx-widgets-wayland.diff
  ];

  # Custom patchPhase: stdenv unpacks the source as a subdirectory (named
  # after the source path) and makes it writable; the wxWidgets patch must
  # be applied from inside its submodule. ${./patches/...} interpolates
  # each patch file's store path (stdenv sets no usable PATCH_PATH here).
  patchPhase = ''
    # stdenv cd's into the source root after unpackPhase, so the CWD here is
    # normally already the root; be robust if it is not. Only the root has
    # both CMakeLists.txt and xenia-build.py (third_party/ has the former).
    SRCROOT="."
    if [ ! -f CMakeLists.txt ] || [ ! -f xenia-build.py ]; then
      SRCROOT=""
      for d in *; do
        if [ -d "$d" ] && [ -f "$d/CMakeLists.txt" ] && [ -f "$d/xenia-build.py" ]; then SRCROOT="$d"; break; fi
      done
    fi
    if [ -z "$SRCROOT" ]; then echo "patchPhase: source root not found in $(pwd)"; exit 1; fi
    pushd "$(cd "$SRCROOT" && pwd)"
    patch -p1 -i ${./patches/xenia-edge-cmake.diff}
    pushd third_party/wxWidgets
    patch -p1 -i ${./patches/wx-widgets-wayland.diff}
    popd
    popd
  '';

  # Compiler: the caller passes `stdenv` as clangStdenv (see
  # xenia-edge-overlay.nix), so the CC wrapper exports CC/CXX=clang —
  # configurePhase needs no -DCMAKE_*_COMPILER flags.
  nativeBuildInputs = [ cmake ninja pkg-config python3 patchelf ];
  buildInputs = all;

  preConfigure = ''
    # pkg-config stubs for module names nixpkgs has no .pc file for.
    # (preConfigure: must exist before configurePhase's cmake/pkg-config.)
    mkdir -p stub-pc
    for m in ${lib.concatStringsSep " " stubModules}; do
      {
        echo "Name: $m"
        echo "Version: 99999.0"
        echo "Description: nixpkgs .pc tree stub"
      } > "stub-pc/$m.pc"
    done
    export PKG_CONFIG_PATH="$PWD/stub-pc:$PKG_CONFIG_PATH"
    # Same CMAKE_PREFIX_PATH as the verified devShell: out of every
    # build input, plus the dev outputs of the multi-output packages.
    export CMAKE_PREFIX_PATH="${lib.concatStringsSep ":" ((map (d: d.outPath) all) ++ [ fmt.dev zstd.dev zstd.out snappy.dev miniaudio.dev imgui.lib])}"
    # CMake finds slangc via $SLANGC_PATH (takes precedence over the
    # .slang/*/bin/slangc glob, so no vendored slang is built).
    export SLANGC_PATH="${shader-slang}/bin/slangc"
  '';

  configurePhase = ''
    # The default configurePhase (which runs the preConfigure/postConfigure
    # hooks) is replaced by this variable, so run the hook explicitly.
    runHook preConfigure
    # CWD is the source root (stdenv cd's there after unpackPhase); be
    # robust if not. Only the root has both CMakeLists.txt and
    # xenia-build.py.
    SRC_DIR="."
    if [ ! -f CMakeLists.txt ] || [ ! -f xenia-build.py ]; then
      SRC_DIR=""
      for d in *; do
        if [ -d "$d" ] && [ -f "$d/CMakeLists.txt" ] && [ -f "$d/xenia-build.py" ]; then SRC_DIR="$d"; break; fi
      done
    fi
    if [ -z "$SRC_DIR" ]; then echo "configurePhase: source root not found in $(pwd)"; exit 1; fi
    SRC_DIR=$(cd "$SRC_DIR" && pwd)
    echo "build env: CWD=$(pwd) SRC_DIR=$SRC_DIR"
    # Bake the pinned runtime data where the CMake consumers expect it,
    # before cmake: xe_embed_compressed_bundle() runs embed_bundle.py at
    # configure time and hard-fails if the paths are missing.
    mkdir -p "$SRC_DIR/build"
    cp -r ${dataRepos} "$SRC_DIR/build/data_repos"
    mkdir -p "$NIX_BUILD_TOP/build"
    cd "$NIX_BUILD_TOP/build"
    # Exact format of xenia-build.py's generate_version_h(), without
    # running xenia-build.py (which requires its own toolchain).
    cat > version.h <<'EOF'
// Autogenerated by xenia-build.py.
#ifndef GENERATED_VERSION_H_
#define GENERATED_VERSION_H_
#define XE_BUILD_BRANCH "edge"
#define XE_BUILD_COMMIT "f466500c3bec97ac0a070f183ecc27d30ef40579"
#define XE_BUILD_COMMIT_SHORT "f466500c3"
#define XE_BUILD_DATE __DATE__
#endif  // GENERATED_VERSION_H_
EOF
    cmake -G Ninja -DCMAKE_BUILD_TYPE=Release -DXENIA_ENABLE_LTO=OFF "$SRC_DIR"
  '';

  buildPhase = ''
    cd "$NIX_BUILD_TOP/build"
    ninja -j$NIX_BUILD_CORES
  '';

  installPhase = ''
    BUILD_DIR="$NIX_BUILD_TOP/build"
    install -Dm755 "$BUILD_DIR/bin/Linux/xenia_edge" -t $out/bin
    # Every shared library the binary links or dlopens now lives in
    # /nix/store (including libSDL3.so.0, from nixpkgs sdl3.lib, whose
    # store dir CMake recorded in RUNPATH via the imported target), so no
    # build-sandbox path can remain. Assert it rather than rewrite: any
    # /nix/var/nix/builds entry means an in-tree shared lib slipped back.
    RPATH="$(patchelf --print-rpath $out/bin/xenia_edge)"
    if printf '%s\n' "$RPATH" | tr ':' '\n' | grep -q "^/nix/var/nix/builds/"; then
      echo "installPhase: forbidden build-sandbox RUNPATH entry" >&2
      printf '%s\n' "$RPATH" | tr ':' '\n'
      exit 1
    fi
  '';

  # libvulkan.so.1 is dlopen'd at runtime, never linked — so it is not a
  # DT_NEEDED and CMake never recorded its store dir in RUNPATH. This must
  # run in postFixup: nixpkgs' patchelf setup hook runs `patchelf
  # --shrink-rpath` over every ELF in $out during fixupPhase, and
  # shrink-rpath drops entries whose directory does not satisfy a
  # DT_NEEDED — a dlopen'd lib has none, so an installPhase add would be
  # silently deleted. DT_RUNPATH is consulted when resolving
  # dlopen("libvulkan.so.1"), before the /lib and /usr/lib fallbacks.
  postFixup = ''
    patchelf --add-rpath "${vulkan-loader}/lib" "$out/bin/xenia_edge"
  '';

  doCheck = false;

  meta = with lib.licenses; {
    description = "Experimental Xbox One emulator (has207/xenia-edge fork, branch edge)";
    homepage = "https://github.com/has207/xenia-edge";
    license = bsd3;
    platforms = [ "x86_64-linux" ];
    mainProgram = "xenia_edge";
  };
}
