# Test build: same contents as gowbase.nix + iputils (ping) + dnsutils (DNS tools).
# Source is parameterized so we can pin to an exact nixos-unstable rev already in
# the warm store (keeps the emulator builds warm / avoids a full rebuild).
{ src ? /nix/store/yxkqzvl5bf7knrh55lbl5xjxksq6ydmp-source }:

let
  pkgs = import src {
    overlays = [ (import ./xenia-edge-overlay.nix) ];
  };
  etc = pkgs.lib.fileset.toSource {
    root = ./.;
    fileset = ./etc;
  };
  opt = pkgs.lib.fileset.toSource {
    root = ./.;
    fileset = ./opt;
  };
  entrypoint = pkgs.lib.fileset.toSource {
    root = ./.;
    fileset = ./entrypoint.sh;
  };
  share_dir= pkgs.lib.fileset.toSource {
    root = ./.;
    fileset = ./share;
  };
  cfg_dir = pkgs.lib.fileset.toSource {
    root = ./.;
    fileset = ./cfg;
  };
  vulkan-icd-etc = pkgs.runCommand "vulkan-icd-etc" {} ''
    mkdir -p $out/etc/vulkan/icd.d
    cp ${pkgs.mesa}/share/vulkan/icd.d/*.json $out/etc/vulkan/icd.d/
  '';
in pkgs.dockerTools.buildLayeredImage {
  name = "hello-docker";
  tag = "nettest";
  contents = [
    pkgs.mesa
    pkgs.mesa.opencl
    pkgs.mesa.cross_tools
    pkgs.mesa.spirv2dxil
    pkgs.egl-gbm
    pkgs.vulkan-headers
    pkgs.vulkan-loader
    pkgs.coreutils
    pkgs.curl
    pkgs.ffmpeg
    pkgs.jq
    pkgs.dbus
    pkgs.libGLU
    pkgs.gtk3
    pkgs.sdl2-compat
    pkgs.libdrm
    pkgs.p7zip
    pkgs.qt5.qtbase
    pkgs.qt6.qtbase
    pkgs.wget
    pkgs.x11docker
    pkgs.clinfo
    pkgs.vulkan-tools
    pkgs.libusb1
    pkgs.xz
    pkgs.gosu
    pkgs.gnused
    pkgs.getent
    pkgs.coreutils
    pkgs.shadow
    pkgs.glibc
    pkgs.xwayland
    pkgs.foot
    pkgs.libxcb-cursor
    pkgs.qt6.qtwayland
    pkgs.findutils
    pkgs.strace
    pkgs.xcb-util-cursor
    pkgs.gamescope
    pkgs.waybar
    pkgs.sway
    pkgs.mangohud
    pkgs.xdpyinfo
    pkgs.xkbcomp
    pkgs.xdg-desktop-portal
    pkgs.xdg-desktop-portal-gtk
    pkgs.mako
    pkgs.systemd
    pkgs.fontconfig
    pkgs.glibcLocales

    # NEW: DNS + ping for the internet-access test
    pkgs.iputils        # provides /bin/ping
    pkgs.dnsutils       # bind dig/host/nslookup (DNS resolution tools)

    etc
    opt
    entrypoint
    share_dir
    cfg_dir
    vulkan-icd-etc

    # The emulator for this image: has207/xenia-edge fork (branch edge).
    pkgs.xenia-edge

    pkgs.pegasus-frontend

    pkgs.bash
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
