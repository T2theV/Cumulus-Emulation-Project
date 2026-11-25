# cep-tiny-mesa — gowbase-tiny + Mesa WITHOUT llvmpipe/zink/lavapipe (drops the ~550 MB LLVM).
# Build: docker cp into agent-nix:/root/cumulus/nix/ then:
#   NIXPKGS_ALLOW_UNFREE=1 nix-build gowbase-tiny-mesa.nix
# Diff from gowbase-tiny.nix:
#   1) name -> "cep-tiny-mesa"
#   2) adds the ./no-llvmpipe.nix overlay (Mesa without LLVM software drivers)
let
  nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/tarball/nixos-unstable";
  pkgs = import nixpkgs { overlays = [
	(import ./xenia-edge-overlay.nix)
	(import ./no-llvmpipe.nix)
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
  name = "cep-tiny-mesa";
  tag = "latest";
  contents = [
    # GPU: hardware DRI + Vulkan, WITHOUT llvmpipe/zink/lavapipe (no LLVM).
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

    # display / windowing
    pkgs.gamescope
    pkgs.foot
    pkgs.waybar
    pkgs.libxcb-cursor
    pkgs.xcb-util-cursor
    pkgs.xkbcomp

    # Qt6 (RPCS3 QML + PCSX2)
    pkgs.qt6.qtbase
    pkgs.qt6.qtwayland

    # Emulators: all 8
    pkgs.xenia-edge
    pkgs.dolphin-emu
    pkgs.flycast
    pkgs.pcsx2
    pkgs.rmg
    pkgs.rpcs3
    pkgs.xemu
    pkgs.eden

    # Pegasus front-end
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
