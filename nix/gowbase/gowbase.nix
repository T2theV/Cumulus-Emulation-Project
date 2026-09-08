let
  pkgs = import <nixpkgs> {};
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
in pkgs.dockerTools.buildLayeredImage {
  name = "hello-docker";
  tag = "latest";
  contents = [ 
#    pkgs.curl
#    pkgs.ffmpeg
#    pkgs.jq
#    pkgs.dbus
#    pkgs.libGLU
#    pkgs.gtk3
#    pkgs.sdl2-compat
#    pkgs.vulkan-headers
#    pkgs.p7zip
#    pkgs.qt5.qtbase
#    pkgs.qt6.qtbase
#    pkgs.wget
#    pkgs.x11docker
#    pkgs.mesa
#    pkgs.libusb1
#    pkgs.xz
#    pkgs.gosu
    
    etc
    opt
    entrypoint
    
#    pkgs.flycast
   ];
  config = {
    Cmd = [ "/bin/flycast" "--version" ];
    Env = [
      "PUID=1000"
      "PGID=1000"
      "UMASK=000"
      "UNAME=retro"
      "HOME=/home/retro"
      "TZ=America/Chicago" 
      "NEEDRESTART_SUSPEND=1"
    ];
  };
  
}