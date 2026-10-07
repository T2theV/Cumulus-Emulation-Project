#!/bin/bash
#MESA=/nix/store/gqpsfqzgbcbwbh12n3sjxk2x4gqgy8lq-mesa-26.1.3
MESA=/nix/store/z5wmfi7agarwjlqb456f2z2r4vsmjad4-mesa-26.2.4
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
