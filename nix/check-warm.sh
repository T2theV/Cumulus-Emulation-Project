#!/bin/bash
# usage: check-warm.sh <nixos-unstable-source-hash>
c=$1
SRC="/nix/store/$c-source"
cd /root/cumulus/nix
P=$(nix eval --impure --extra-experimental-features nix-command --expr "
  let pkgs = import $SRC {
    overlays=[(import /root/cumulus/nix/xenia-edge-overlay.nix)];
    config.allowUnfree=true;
  };
  in pkgs.lib.concatStringsSep \"\n\" (builtins.map (a: a.outPath) [
    pkgs.xenia-edge
    pkgs.pegasus-frontend
    pkgs.ffmpeg
    pkgs.mesa
    pkgs.gtk3
    pkgs.qt5.qtbase
    pkgs.qt6.qtbase
    pkgs.xwayland
    pkgs.gamescope
    pkgs.glibc
    pkgs.bash
    pkgs.sdl2-compat
    pkgs.vulkan-loader
    pkgs.findutils
    pkgs.strace
    pkgs.p7zip
    pkgs.iputils
    pkgs.dnsutils
  ]);
" 2>/dev/null)
total=0; miss=0
while IFS= read -r line; do
  [ -z "$line" ] && continue
  total=$((total+1))
  if [ -e "$line" ]; then :; else miss=$((miss+1)); echo "  MISSING: $line"; fi
done <<< "$P"
echo "candidate $c: $miss/$total expensive inputs MISSING"
