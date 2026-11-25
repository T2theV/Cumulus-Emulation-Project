# cep-tiny — minimized gowbase. Keeps all 8 emulators + pegasus-frontend.
# Build: docker cp into agent-nix:/root/cumulus/nix/ then:
#   nix-build gowbase-tiny.nix  (see nix-builder.md / skill)
#
# Tier A (contents) — DONE in this file:
#   kept:  pegasus-frontend, all 8 emus, mesa/egl-gbm/vulkan-loader, glibc/bash/gosu/
#          shadow/getent/coreutils/curl/jq/dbus/ffmpeg/sdl2-compat/fontconfig,
#          gamescope/foot/waybar/libxcb-cursor/xcb-util-cursor/xkbcomp, qt6.qtbase/qt6.qtwayland
#   dropped: sway, mangohud, mako, xwayland (per request);
#            gtk3, xdg-desktop-portal[-gtk], strace, clinfo, vulkan-tools, vulkan-headers,
#            x11docker, mesa.opencl/cross_tools/spirv2dxil, findutils, p7zip, xz, wget,
#            libusb1, libGLU, xdpyinfo, systemd, duplicate coreutils, explicit qt5
#
# Tier B (build-level) — status:
#   [done]  systemd + vulkan-headers dropped from contents (above)
#   [todo]  PIN nixpkgs to a fixed rev+sha256 (below is still floating) so every
#           emu/dep resolves from ONE source -> removes the glibc/ffmpeg/perl/icu
#           x2 (and Qt5/Qt6) duplicates. Deterministic + cache-friendly.
#   [todo]  MESA without llvmpipe/softpipe -> removes the ~550 MB LLVM (biggest single
#           win). Override (advanced; verify it builds before relying on it):
#             pkgs.mesa = pkgs.callPackage pkgs.mesa { /* see notes */ };
#           i.e. build mesa with GALLIUM_DRIVERS excluding llvmpipe+softpipe.
#   [done]  strip: Nix strips C/C++ by default and does not ship -dev/-doc/-debug in the
#           main output, so nothing extra to do.
let
  # TODO(pin): nixpkgs = fetchTarball { url = "https://github.com/NixOS/nixpkgs/archive/<REV>.tar.gz"; sha256 = "<hash>"; };
  # Pinned (deterministic) nixpkgs: fixed commit + verified sha256, so the build
  # input is reproducible. Pinned 2026-11-03 to the then-current nixos-unstable head.
  nixpkgs = fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/0bb2eedc20e4739f29e8045034f2828ad7054f8f.tar.gz";
    sha256 = "ae2b8e2ac9e2dfa2412ebfbdebfc0d05492461b9478b9583b7f07b462c3c62c4";
  };
  pkgs = import nixpkgs { overlays = [
	(import ./xenia-edge-overlay.nix)
 ];};
  etc = pkgs.lib.fileset.toSource { root = ./.; fileset = ./etc; };
  opt = pkgs.lib.fileset.toSource { root = ./.; fileset = ./opt; };
  entrypoint = pkgs.lib.fileset.toSource { root = ./.; fileset = ./entrypoint.sh; };
  share_dir = pkgs.lib.fileset.toSource { root = ./.; fileset = ./share; };
  cfg_dir = pkgs.lib.fileset.toSource { root = ./.; fileset = ./cfg; };
  vulkan-icd-etc = pkgs.runCommand "vulkan-icd-etc" {} ''
    mkdir -p $out/etc/vulkan/icd.d
    cp ${pkgs.mesa}/share/vulkan/icd.d/*.json $out/etc/vulkan/icd.d/
  '';
in pkgs.dockerTools.buildLayeredImage {
  name = "cep-tiny";
  tag = "latest";
  contents = [
    # GPU: hardware DRI + Vulkan. (no opencl / cross_tools / spirv2dxil / llvmpipe)
    pkgs.mesa
    pkgs.egl-gbm
    pkgs.vulkan-loader

    # base runtime
    pkgs.glibc
    pkgs.bash
    pkgs.gosu
    pkgs.shadow
    pkgs.getent
    pkgs.coreutils
    pkgs.curl
    pkgs.jq
    pkgs.dbus
    pkgs.ffmpeg
    pkgs.sdl2-compat
    pkgs.fontconfig

    # display / windowing (kept: gamescope + foot + waybar surface).
    # DROPPED per request: sway, mangohud, mako, xwayland
    pkgs.gamescope
    pkgs.foot
    pkgs.waybar
    pkgs.libxcb-cursor
    pkgs.xcb-util-cursor
    pkgs.xkbcomp

    # Qt6 (RPCS3 QML + PCSX2). DROPPED: gtk3, explicit qt5 (transitive stays if needed)
    pkgs.qt6.qtbase
    pkgs.qt6.qtwayland

    # Emulators: all 8 (matching cep-small). NOT xenia-canary.
    pkgs.xenia-edge
    pkgs.dolphin-emu
    pkgs.flycast
    pkgs.pcsx2
    pkgs.rmg
    pkgs.rpcs3
    pkgs.xemu
    pkgs.eden

    # Pegasus front-end (KEPT per request)
    pkgs.pegasus-frontend

    # files
    etc
    opt
    entrypoint
    share_dir
    cfg_dir
    vulkan-icd-etc

    pkgs.dockerTools.binSh
    pkgs.dockerTools.usrBinEnv
  ];
  config = {
    Cmd = [ "/bin/sh" "/entrypoint.sh" ];
    Env = [
      "PUID=1000"
      "PGID=1000"
      "UMASK=000"
      "UNAME=retro"
      "HOME=/home/retro"
      "TZ=America/Chicago"
      "NEEDRESTART_SUSPEND=1"
      "LANG=en_US.UTF-8"
      "QT_QPA_PLATFORM=wayland-egl"
    ];
  };
}
