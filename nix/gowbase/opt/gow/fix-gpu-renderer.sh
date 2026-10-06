#!/bin/bash
MESA=/nix/store/gqpsfqzgbcbwbh12n3sjxk2x4gqgy8lq-mesa-26.1.3
mkdir -p /home/retro/.config/vulkan/icd.d /etc/glvnd/egl_vendor.d
ln -sf "$MESA/share/vulkan/icd.d/radeon_icd.x86_64.json" \
       /home/retro/.config/vulkan/icd.d/radeon_icd.x86_64.json
ln -sf "$MESA/share/glvnd/egl_vendor.d/50_mesa.json" \
       /etc/glvnd/egl_vendor.d/50_mesa.json
mkdir /run
ln -sfnf "$MESA" /run/opengl-driver
