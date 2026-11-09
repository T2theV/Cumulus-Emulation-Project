#!/usr/bin/env bash
#
# 50-eden-firmware.sh — install Eden (Switch) firmware + keys on first boot.
#
# Runs as root during container init (sourced by /entrypoint.sh with `set -e`),
# after 40-cumulus-canned.sh. Installs a dropped Switch firmware zip and the
# prod/title keys into the retro user's Eden data dir, but ONLY when a firmware
# zip is present in FIRMWARE_DIR and the firmware is not already installed, so
# returning boots skip it (fast). Nonfatal: a missing/failed install must never
# block container startup -- Eden simply won't run until it is installed.
#
# Sources (mounted ROMs volume):
#   firmware : /ROMs/switch/firmware/*.zip
#   keys     : /ROMs/switch/keys/{prod.keys,title.keys,key_retail.bin}
# Install logic: /etc/cumulus-emu/EdenFirmwareInstall/install-eden-firmware.sh
#                (the "EdenFirmwareInstall" gadget, see gowbase.nix).
#
HOME="${HOME:-/home/retro}"
data_dir="${HOME}/.local/share/eden"
registered="${data_dir}/nand/system/Contents/registered"
firmware_dir="/ROMs/switch/firmware"
keys_dir="/ROMs/switch/keys"
gadget="/etc/cumulus-emu/EdenFirmwareInstall/install-eden-firmware.sh"

# Already installed? -> nothing to do (fast path on returning boots).
present=""
for f in "$registered"/*.nca "$registered"/*.NCA; do
  [ -f "$f" ] && present="$f" && break
done
if [ -n "$present" ]; then
  gow_log "[50-eden-firmware] Eden firmware already present in $registered; skipping"
  exit 0
fi

# Nothing dropped yet? -> skip silently (user installs on demand).
fw=""
for f in "$firmware_dir"/*.zip "$firmware_dir"/*.ZIP "$firmware_dir"/*.7z; do
  [ -f "$f" ] && fw="$f" && break
done
if [ -z "$fw" ]; then
  gow_log "[50-eden-firmware] no Switch firmware zip in $firmware_dir; skipping"
  exit 0
fi

if [ -x "$gadget" ]; then
  gow_log "[50-eden-firmware] installing Eden firmware + keys (first boot)..."
  gosu "${UNAME:-retro}" bash -c "HOME=${HOME} FIRMWARE_DIR=${firmware_dir} KEYS_DIR=${keys_dir} ${gadget}" \
    || gow_log "[50-eden-firmware] firmware install failed (nonfatal); retry: gosu ${UNAME:-retro} ${gadget}"
else
  gow_log "[50-eden-firmware] WARN: gadget not found at $gadget; skipping (nonfatal)"
fi
