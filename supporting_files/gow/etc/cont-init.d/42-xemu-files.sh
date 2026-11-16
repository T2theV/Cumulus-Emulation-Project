#!/bin/sh
# 42-xemu-files.sh — seed XEMU (Xbox One) sys files and point xemu.toml at them.
#
# The shipped xemu.toml (seeded by 40-cumulus-canned.sh) has a [sys.files]
# block with $HOME-literal placeholder paths. XEMU needs:
#   bootrom  mcpx_1.0.bin          (from /ROMs/bios/xbox/XEMU FILES/)
#   flashrom Complex_4627v1.03.bin (from /ROMs/bios/xbox/XEMU FILES/)
#   eeprom   eeprom.bin            (not seeded at all — XEMU creates/owns
#                                    it on its own; users edit it themselves)
#   hdd      xbox_hdd.qcow2        (restored by 90-xbox-hdd.sh)
#
# This script copies the two ROMs files into $HOME/.local/share/xemu/
# (flat, matching the user's toml layout), rewrites [sys.files] with real
# absolute paths, and drops dvd_path — the disc is passed by the launcher
# (pegasus) at startup, so no dvd line is wanted in the config.
#
# Nonfatal: a missing /ROMs tree must never block container boot.

XEMU_DIR="${HOME:-/home/retro}/.local/share/xemu"
TOML="${XEMU_DIR}/xemu/xemu.toml"
XBOX_BIOS="/ROMs/bios/xbox/XEMU FILES"

echo "[42-xemu-files] Seeding XEMU sys files"

# copy_if_missing SRC DEST — copy SRC over DEST only if DEST is absent
copy_if_missing() {
  src="$1"
  dest="$2"
  if [ ! -f "$dest" ]; then
    if [ -f "$src" ]; then
      cp "$src" "$dest"
      echo "[42-xemu-files] Copied ${src##*/} to ${dest}"
    else
      echo "[42-xemu-files] WARNING: missing source ${src} (skipping)"
    fi
  fi
}

mkdir -p "$XEMU_DIR"
copy_if_missing "${XBOX_BIOS}/Boot ROM Image/mcpx_1.0.bin" "${XEMU_DIR}/mcpx_1.0.bin"
copy_if_missing "${XBOX_BIOS}/BIOS/Complex_4627v1.03.bin" "${XEMU_DIR}/Complex_4627v1.03.bin"

# Rewrite the [sys.files] block in the toml. It is the last section of
# this config, so delete from the header to EOF and append a clean block.
if [ -f "$TOML" ]; then
  sed -i '/^\[sys\.files\]/,$d' "$TOML"
  {
    printf '\n[sys.files]\n'
    printf "bootrom_path = '%s/mcpx_1.0.bin'\n" "$XEMU_DIR"
    printf "flashrom_path = '%s/Complex_4627v1.03.bin'\n" "$XEMU_DIR"
    printf "eeprom_path = '%s/eeprom.bin'\n" "$XEMU_DIR"
    printf "hdd_path = '%s/xbox_hdd.qcow2'\n" "${HOME:-/home/retro}"
  } >> "$TOML"
  echo "[42-xemu-files] Rewrote [sys.files] in ${TOML}"
fi

# We run as root during init; xemu runs as retro. Hand ownership back
# (same trap as the 40 seeder — root-owned files crash the emulator).
# The hdd is chowned by 90-xbox-hdd.sh, which runs later.
chown -R retro:retro "$XEMU_DIR" 2>/dev/null \
  || echo "[42-xemu-files] warning: could not chown xemu files to retro"

return 0
