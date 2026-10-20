let
  nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/tarball/nixos-unstable";
  pkgs = import nixpkgs { overlays = [ 
	(import ./eden-overlay.nix)
	(import ./eden-overlay-hash.nix)
	(import ./dolphin-emu-overlay.nix)
	(import ./dolphin-emu-overlay-hash.nix)
	(import ./flycast-overlay.nix)
	(import ./flycast-overlay-hash.nix)
	(import ./pcsx2-overlay.nix)
	(import ./pcsx2-overlay-hash.nix)
	(import ./rmg-overlay.nix)
	(import ./rmg-overlay-hash.nix)
	(import ./rpcs3-overlay.nix)
	(import ./rpcs3-overlay-hash.nix)
	(import ./xenia-canary-overlay.nix)
	(import ./xenia-canary-overlay-hash.nix)
 ];};
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

#  dol_retro = import ./dolphin.nix;
in pkgs.dockerTools.buildLayeredImage {
  name = "hello-docker";
  tag = "latest";
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

    etc
    opt
    entrypoint
    share_dir
    cfg_dir

#    dol_retro.dolphin-new
    pkgs.dolphin-emu
    pkgs.flycast
    pkgs.rpcs3
    pkgs.xemu
    pkgs.rmg
    pkgs.xenia-canary
    pkgs.eden
    pkgs.pcsx2

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
