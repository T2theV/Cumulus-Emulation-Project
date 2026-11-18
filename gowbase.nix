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

  # --------------------------------------------------------------------------
  # cartouche-libs.sh — runtime library symlinks for cartouche (Godot).
  #
  # Cartouche dlopens its display/audio libraries by SONAME at runtime, but
  # Nix glibc only searches the binary's own RUNPATH, LD_LIBRARY_PATH and
  # the ld.so cache — never /lib or /usr/lib. Mesa's Vulkan ICD resolves its
  # own deps through Nix RUNPATH, but the Godot export can't, so the image's
  # libs are invisible to cartouche and startup fails.
  #
  # This script creates SONAME symlinks in glibc's store lib dir (which is
  # on every binary's RUNPATH) for exactly the libs a running cartouche
  # loads (verified via /proc/PID/maps): wayland client/cursor,
  # vulkan-loader, xkbcommon, fontconfig (plus its deps freetype/libpng/
  # zlib/bzip2/expat), pulseaudio. No glvnd libEGL/libGL (the Vulkan+Wayland
  # path never loads EGL) and no libgbm/libxcb/libdrm (mesa's Vulkan ICD
  # resolves those itself).
  #
  # Like fix-gpu-renderer.sh, the store paths are interpolated at eval time
  # so this script always matches the nixpkgs rev this image was built with.
  # --------------------------------------------------------------------------
  cartouche-libs = pkgs.writeScript "cartouche-libs.sh" ''
      #!/bin/sh
      # Sourced from /entrypoint.sh — runs as root before gosu drops
      # privileges. Safe under the entrypoint's set -e: every command has
      # an exit-0 fallback and nothing bare-exits.

      cartouche_libs_setup() {
        cart_glibc_lib=${pkgs.glibc}/lib
        [ -d "$cart_glibc_lib" ] || return 0

        cart_link() {
          name=$1 target=$2
          [ -f "$target" ] || return 0
          ln -sfn "$target" "$cart_glibc_lib/$name"
        }

        cart_link libwayland-client.so.0  ${pkgs.wayland}/lib/libwayland-client.so.0
        cart_link libwayland-cursor.so.0  ${pkgs.wayland}/lib/libwayland-cursor.so.0
        cart_link libvulkan.so.1   ${pkgs.vulkan-loader}/lib/libvulkan.so.1
        cart_link libxkbcommon.so.0 ${pkgs.libxkbcommon}/lib/libxkbcommon.so.0
        cart_link libfontconfig.so.1 ${pkgs.fontconfig.lib}/lib/libfontconfig.so.1
        cart_link libfreetype.so.6 ${pkgs.freetype}/lib/libfreetype.so.6
        cart_link libpng16.so.16 ${pkgs.libpng}/lib/libpng16.so.16
        cart_link libz.so.1 ${pkgs.zlib}/lib/libz.so.1
        cart_link libbz2.so.1 ${pkgs.bzip2.out}/lib/libbz2.so.1
        cart_link libexpat.so.1 ${pkgs.expat}/lib/libexpat.so.1
        cart_link libpulse.so.0 ${pkgs.pulseaudio}/lib/libpulse.so.0
        cart_link libpulse-simple.so.0 ${pkgs.pulseaudio}/lib/libpulse-simple.so.0
      }

      cartouche_libs_setup
      unset -f cartouche_libs_setup
  '';

  # Cartouche (ROM cartridge launcher, Godot 4.7.2) — replaces
  # pegasus-frontend in this test image. Build lives in
  # supporting_files/cartouche/package.nix.
  cartouche = import ./supporting_files/cartouche/package.nix { pkgs = pkgs; };

#  dol_retro = import ./emus/dolphin.nix;
in pkgs.dockerTools.buildLayeredImage {
  name = "cep-cartouche";
  tag = "ultra-nostalgia";
  contents = [ 
  (pkgs.runCommand "entrypoint" {} ''
    mkdir -p $out
    cp ${./supporting_files/gow/entrypoint.sh} $out/entrypoint.sh
  '')
  (pkgs.runCommand "etc" {} ''
    mkdir -p $out
    cp -r ${./supporting_files/gow/etc} $out/etc
    # cp -r preserves the store path's read-only perms (555 dirs / 444
    # files), so make the copied tree writable before adding
    # cartouche-libs.sh below.
    chmod -R u+w $out
    # cartouche-libs.sh is generated at evaluation time (see above) so its
    # glibc store path always matches this build's nixpkgs revision — it
    # cannot be a static file here.
    cp ${cartouche-libs} $out/etc/cont-init.d/25-cartouche-libs.sh
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
    # EdenFirmwareInstall gadget -> /etc/cumulus-emu/EdenFirmwareInstall/
    # (auto-run on first boot by /etc/cont-init.d/50-eden-firmware.sh when a
    #  Switch firmware zip is dropped in /ROMs/bios/switch)
    cp -r ${./gadgets/root/EdenFirmwareInstall} $out/etc/cumulus-emu/EdenFirmwareInstall
    chmod +x $out/etc/cumulus-emu/EdenFirmwareInstall/install-eden-firmware.sh
    # XboxHddRestore gadget -> /etc/cumulus-emu/XboxHddRestore/
    # (auto-run at boot by /etc/cont-init.d/90-xbox-hdd.sh; restores XEMU's
    #  hdd image into $HOME from the ROMs volume if it is missing)
    cp -r ${./gadgets/root/XboxHddRestore} $out/etc/cumulus-emu/XboxHddRestore
    chmod +x $out/etc/cumulus-emu/XboxHddRestore/ensure-xbox-hdd.sh
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
  # /tmp must exist from container start: the entrypoint sources every
  # /etc/cont-init.d/*.sh before fix-gpu-renderer.sh (which does
  # mkdir -p /tmp), and init gadgets such as PS3FirmwareInstall write
  # /tmp during init. Baked into the image; fix-gpu-renderer.sh's
  # mkdir -p remains as a harmless no-op.
  (pkgs.runCommand "tmp" {} ''
    mkdir -p $out/tmp
    chmod 1777 $out/tmp
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
    pkgs.pipewire
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
    # Explicit outputs the cartouche-libs.sh script symlinks at boot —
    # the default outputs (pkgs.fontconfig = -bin, pkgs.bzip2 = -bin)
    # don't carry the libs, so pin the outputs that do.
    pkgs.fontconfig.lib
    pkgs.bzip2.out
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

    # Cartouche replaces pegasus-frontend in this test image.
    cartouche

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
      "GDK_BACKEND=wayland"
      "CARTOUCHE_CONFIG=/home/retro/.config/cartouche/cartouche.conf"
      "CARTOUCHE_GAMES_DIR=/ROMs"
    ];
  };
  
}
