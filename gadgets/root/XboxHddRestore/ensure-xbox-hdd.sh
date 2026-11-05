#!/usr/bin/env bash
#
# ensure-xbox-hdd.sh   (gadget: XboxHddRestore)
#
# Ensure XEMU's Xbox hard disk image exists at $HOME/xbox_hdd.qcow2 (the
# hdd_path in ~/.local/share/xemu/xemu/xemu.toml). If it is missing, restore
# it from the copy kept on the ROMs volume:
#   /ROMs/bios/xbox/XEMU FILES/Xbox Hard Disk Image/xbox_hdd.qcow2
#
# Shipped in the image at:
#   /etc/cumulus-emu/XboxHddRestore/ensure-xbox-hdd.sh
# (see the "cumulus-emu-canned" derivation in gowbase.nix) and invoked at
# every boot by /etc/cont-init.d/90-xbox-hdd.sh.
#
# Idempotent: if the image is already in $HOME this is a no-op, so returning
# boots are instant. The restore only ever copies the ROMs copy IN -- it
# never overwrites a user's live image.
#
# Run it as the emulator user (the owner of $HOME/xbox_hdd.qcow2):
#   docker exec -u retro <container> \
#     /etc/cumulus-emu/XboxHddRestore/ensure-xbox-hdd.sh
#
# Paths can be overridden for testing:
#   XBOX_HDD_SOURCE=... XBOX_HDD_TARGET=... ensure-xbox-hdd.sh

set -eu

die() { echo "ERROR: $*" >&2; exit 1; }

HOME="${HOME:-/home/retro}"
SOURCE="${XBOX_HDD_SOURCE:-/ROMs/bios/xbox/XEMU FILES/Xbox Hard Disk Image/xbox_hdd.qcow2}"
TARGET="${XBOX_HDD_TARGET:-${HOME}/xbox_hdd.qcow2}"

# Already present? -> nothing to do (the common path on returning boots).
if [ -f "$TARGET" ]; then
    echo "[xbox-hdd] ${TARGET} already present - nothing to do"
    exit 0
fi

[ -f "$SOURCE" ] || die "${TARGET} missing and source ${SOURCE} not found - cannot restore"

echo "[xbox-hdd] ${TARGET} missing - copying from ${SOURCE}"
cp -f "$SOURCE" "$TARGET"
chmod 664 "$TARGET"
echo "[xbox-hdd] restored ${TARGET} ($(du -h "$TARGET" | cut -f1))"
