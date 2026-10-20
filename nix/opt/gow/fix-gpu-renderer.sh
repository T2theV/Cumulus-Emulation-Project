#!/bin/bash
MESA=/nix/store/z5zn9mxnvik2s9h1bpnr1ipa27qhi9py-mesa-26.2.5
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
ln -s /nix/store/ig5ylfz7qcgpmvzip4pxfkp2pfi76s2j-glibc-locales-2.44-25/lib /usr
export LOCALE_ARCHIVE=/usr/lib/locale/locale-archive

