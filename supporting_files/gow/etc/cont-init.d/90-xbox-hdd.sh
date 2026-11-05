#!/usr/bin/env bash
#
# 90-xbox-hdd.sh — ensure XEMU's Xbox HDD image is present in $HOME (idempotent).
#
# Runs as root during container init (sourced by /entrypoint.sh). If the
# emulator's XEMU hard disk image is missing from $HOME (the hdd_path in
# xemu.toml), restore it from the copy kept on the mounted ROMs volume.
# The common returning-boot path (image present) is a fast no-op.
#
# Failure is nonfatal: a failed restore must never block container startup --
# XEMU simply won't run until the image is present.
#
# Restore logic: /etc/cumulus-emu/XboxHddRestore/ensure-xbox-hdd.sh
#                (the "XboxHddRestore" gadget, see gowbase.nix).
#
# NOTE: /entrypoint.sh sources this with `set -e`, so nothing here may return
# nonzero outside a conditional; the gadget call is wrapped in `|| gow_log`.
#
HOME="${HOME:-/home/retro}"
target="${HOME}/xbox_hdd.qcow2"
gadget="/etc/cumulus-emu/XboxHddRestore/ensure-xbox-hdd.sh"

# Already present? -> nothing to do (fast path on returning boots).
if [ -f "$target" ]; then
    gow_log "[90-xbox-hdd] ${target} already present; skipping"
else
    if [ -x "$gadget" ]; then
        gow_log "[90-xbox-hdd] ${target} missing; restoring from ROMs..."
        gosu "${UNAME:-retro}" bash -c "HOME=${HOME} ${gadget}" \
            || gow_log "[90-xbox-hdd] restore failed (nonfatal); retry: gosu ${UNAME:-retro} ${gadget}"
    else
        gow_log "[90-xbox-hdd] WARN: gadget not found at ${gadget}; skipping (nonfatal)"
    fi
fi
