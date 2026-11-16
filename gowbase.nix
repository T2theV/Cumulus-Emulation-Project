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

  # fix-gpu-renderer.sh, generated at evaluation time. The nixpkgs
  # fetchTarball above is floating, so every evaluation of this file
  # resolves to a different /nix/store hash: a static copy of the script
  # (as previously shipped under supporting_files/gow/opt/) bakes in
  # store paths that are no longer present in the image, leaving
  # /run/opengl-driver, the Vulkan ICD and the locale-archive symlinks
  # dangling. ${pkgs.mesa} / ${pkgs.glibcLocales} are interpolated at
  # evaluation time, so the paths in the script always match the
  # revision this file resolves to. The "opt" content below installs it
  # as /opt/gow/fix-gpu-renderer.sh, which entrypoint.sh sources.
  fix-gpu-renderer = pkgs.writeScript "fix-gpu-renderer.sh" ''
    #!/bin/bash
    MESA=${pkgs.mesa}
    GLIBC_LOCALES=${pkgs.glibcLocales}
    mkdir -p /home/retro/.config/vulkan/icd.d /etc/glvnd/egl_vendor.d
    ln -sf "$MESA/share/vulkan/icd.d/radeon_icd.x86_64.json" \
          /home/retro/.config/vulkan/icd.d/radeon_icd.x86_64.json
    ln -sf "$MESA/share/glvnd/egl_vendor.d/50_mesa.json" \
          /etc/glvnd/egl_vendor.d/50_mesa.json
    mkdir -p /run
    ln -sfnf "$MESA" /run/opengl-driver
    mkdir -p /tmp
    chmod 1777 /tmp
    mkdir -p /dev/input
    ln -s "$GLIBC_LOCALES/lib" /usr
    export LOCALE_ARCHIVE=/usr/lib/locale/locale-archive
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
  (pkgs.runCommand "opt" {} ''
    mkdir -p $out
    cp -r ${./supporting_files/gow/opt} $out/opt
    # cp -r preserves the store path's read-only perms (555 dirs / 444 files),
    # so make the copied tree writable before adding fix-gpu-renderer.sh below.
    chmod -R u+w $out
    # fix-gpu-renderer.sh is generated at evaluation time (see above) so
    # its MESA/glibc-locales store paths always match this build's
    # nixpkgs revision — it cannot be a static file here.
    cp ${fix-gpu-renderer} $out/opt/gow/fix-gpu-renderer.sh
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

    # Internet access: ping, DNS lookup, and CA certificates for TLS
    pkgs.iputils        # ping (iputils)
    pkgs.dnsutils       # dig / nslookup (bind dnsutils)
    pkgs.cacert         # CA certificates (nss-cacert) for TLS verification

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
