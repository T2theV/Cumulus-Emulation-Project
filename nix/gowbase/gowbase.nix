let
  pkgs = import <nixpkgs> {system = "x86_64-linux"; overlays = [  ];};
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
  scripts_dir= pkgs.lib.fileset.toSource {
    root = ./.;
    fileset = ./scripts;
  }; 
  cfg_dir = pkgs.lib.fileset.toSource {
    root = ./.;
    fileset = ./cfg;
  };

  dol_retro = import ./dolphin.nix;
in pkgs.dockerTools.buildLayeredImage {
  name = "hello-docker";
  tag = "latest";
  contents = [ 
    pkgs.curl
    pkgs.ffmpeg
    pkgs.jq
    pkgs.dbus
    pkgs.libGLU
    pkgs.gtk3
    pkgs.sdl2-compat
    pkgs.vulkan-headers
    pkgs.p7zip
    pkgs.qt5.qtbase
    pkgs.qt6.qtbase
    pkgs.wget
    pkgs.x11docker
    pkgs.mesa
    pkgs.mesa.opencl
    pkgs.mesa.cross_tools
    pkgs.mesa.spirv2dxil
    pkgs.clinfo
    pkgs.vulkan-tools
    pkgs.libusb1
    pkgs.xz
    pkgs.gosu
    pkgs.coreutils
    pkgs.shadow
    pkgs.glibc
    pkgs.xwayland
    pkgs.egl-gbm
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

    etc
    opt
    entrypoint
    #scripts_dir
    cfg_dir

#    dol_retro.dolphin-new
    pkgs.mesa-demos
    pkgs.dolphin-emu
    pkgs.flycast
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
      "QT_DEBUG_PLUGINS=1"
    ];
  };
  
}
