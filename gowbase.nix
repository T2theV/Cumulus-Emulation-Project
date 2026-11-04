let
  nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/tarball/nixos-unstable";
  pkgs = import nixpkgs { overlays = [
	(import ./overlays/xenia-edge-overlay.nix)
	(import ./overlays/eden-overlay.nix)
	(import ./overlays/eden-overlay-hash.nix)
	(import ./overlays/dolphin-emu-overlay.nix)
	(import ./overlays/dolphin-emu-overlay-hash.nix)
	(import ./overlays/flycast-overlay.nix)
	(import ./overlays/flycast-overlay-hash.nix)
	(import ./overlays/pcsx2-overlay.nix)
	(import ./overlays/pcsx2-overlay-hash.nix)
	(import ./overlays/rmg-overlay.nix)
	(import ./overlays/rmg-overlay-hash.nix)
	(import ./overlays/rpcs3-overlay.nix)
	(import ./overlays/rpcs3-overlay-hash.nix)
 ];};
  # Mesa's Vulkan ICD manifests live in $mesa/share/vulkan/icd.d, which
  # the Vulkan loader never searches: this loader generation searches XDG
  # locations ($HOME/.config/vulkan/icd.d first, then the XDG_CONFIG_DIRS
  # entries, /run/opengl-driver/share, and /usr/share); older loaders
  # search /etc/vulkan/icd.d. dockerTools merges this derivation's etc/
  # into the image's /etc, and cont-init script 20-vulkan-icd.sh
  # symlinks it into $HOME/.config/vulkan/.
  vulkan-icd-etc = pkgs.runCommand "vulkan-icd-etc" {} ''
    mkdir -p $out/etc/vulkan/icd.d
    cp ${pkgs.mesa}/share/vulkan/icd.d/*.json $out/etc/vulkan/icd.d/
  '';

#  dol_retro = import ./emus/dolphin.nix;
in pkgs.dockerTools.buildLayeredImage {
  name = "hello-docker";
  tag = "latest";
  contents = [ 
  (pkgs.runCommand "entrypoint" {} ''
    mkdir -p $out
    cp ${./supporting_files/gow/entrypoint.sh} $out/entrypoint.sh
  '')
  (pkgs.runCommand "etc" {} ''
    mkdir -p $out
    cp -r ${./supporting_files/gow/etc} $out/etc
  '')
  # Canned emulator defaults ("canned init"). The trees land in /etc/cumulus-emu
  # and are seeded into $HOME on first boot by /etc/cont-init.d/40-cumulus-canned.sh
  # (installed via the "etc" layer above) calling /etc/cumulus-emu/overall.sh.
  (pkgs.runCommand "cumulus-emu-canned" {} ''
    mkdir -p $out
    mkdir -p $out/etc/cumulus-emu
    cp -r ${./gadgets/root/config} $out/etc/cumulus-emu/config
    cp -r ${./gadgets/root/local} $out/etc/cumulus-emu/local
    cp ${./gadgets/root/overall.sh} $out/etc/cumulus-emu/overall.sh
    chmod +x $out/etc/cumulus-emu/overall.sh
    # PS3FirmwareInstall gadget -> /etc/cumulus-emu/PS3FirmwareInstall/
    # (auto-run on first boot by /etc/cont-init.d/45-ps3-firmware.sh)
    cp -r ${./gadgets/root/PS3FirmwareInstall} $out/etc/cumulus-emu/PS3FirmwareInstall
    chmod +x $out/etc/cumulus-emu/PS3FirmwareInstall/install-ps3-firmware.sh
  '')
  (pkgs.runCommand "opt" {} ''
    mkdir -p $out
    cp -r ${./supporting_files/gow/opt} $out/opt
  '')
  (pkgs.runCommand "share" {} '' 
    mkdir -p $out
    cp -r ${./supporting_files/gow/share} $out/share
  '')
  (pkgs.runCommand "cfg" {} ''
    mkdir -p $out
    cp -r ${./supporting_files/gow/cfg} $out/cfg
  '')


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

#    etc
#    opt
#    entrypoint
#    share_dir
#    cfg_dir
    vulkan-icd-etc

    # The emulator for this image: has207/xenia-edge fork (branch edge).
    # Package: ./emus/xenia-edge/xenia-edge.nix (overlay: ./overlays/xenia-edge-overlay.nix).
    pkgs.xenia-edge

    pkgs.eden
    pkgs.dolphin-emu
    pkgs.flycast
    pkgs.rpcs3
    pkgs.xemu
    pkgs.rmg
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
