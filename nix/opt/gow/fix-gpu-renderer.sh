#!/bin/bash
MESA=/nix/store/jg8f97fhfmkpccrm3lsxlavkivpjbs72-mesa-26.2.5
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
ln -s /nix/store/fdp9x7rhsspyj0xjv0cczj08fhj6z92y-glibc-locales-2.44-57/lib /usr
export LOCALE_ARCHIVE=/usr/lib/locale/locale-archive

