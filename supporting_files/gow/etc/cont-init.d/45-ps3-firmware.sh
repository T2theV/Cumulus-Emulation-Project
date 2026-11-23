#!/usr/bin/env bash
#
# 45-ps3-firmware.sh — install PS3 firmware on first boot (idempotent).
#
# Runs as root during container init (sourced by /entrypoint.sh), after
# 40-cumulus-canned.sh. Installs the bundled PS3 firmware into the retro user's
# RPCS3 data dir, but ONLY if firmware is not already present, so returning
# boots skip it (fast). Failure is nonfatal: a missing firmware must not block
# container startup -- RPCS3 simply won't run until it's installed.
#
# Firmware source: /ROMs/bios/ps3/ (the mounted ROMs volume).
# Install logic:  /etc/cumulus-emu/PS3FirmwareInstall/install-ps3-firmware.sh
#                 (the "PS3FirmwareInstall" gadget, see gowbase.nix).
#
# NOTE: /entrypoint.sh sources this with `set -e`, so nothing here may return
# nonzero outside a conditional; the install is wrapped in `|| gow_log`.
#
HOME="${HOME:-/home/retro}"
data_dir="${HOME}/.config/rpcs3"
dev_flash="${data_dir}/dev_flash"
gadget="/etc/cumulus-emu/PS3FirmwareInstall/install-ps3-firmware.sh"

# Already installed? -> nothing to do.
if [ -d "${dev_flash}/vsh" ] && [ -d "${dev_flash}/sys" ]; then
    gow_log "[45-ps3-firmware] PS3 firmware already present in ${dev_flash}; skipping"
else
    if [ -x "$gadget" ]; then
        gow_log "[45-ps3-firmware] installing PS3 firmware (first boot)..."
        gosu "${UNAME:-retro}" bash -c "HOME=${HOME} ${gadget}" \
            || gow_log "[45-ps3-firmware] firmware install failed (nonfatal); retry: gosu ${UNAME:-retro} ${gadget}"
    else
        gow_log "[45-ps3-firmware] WARN: gadget not found at ${gadget}; skipping (nonfatal)"
    fi
fi
