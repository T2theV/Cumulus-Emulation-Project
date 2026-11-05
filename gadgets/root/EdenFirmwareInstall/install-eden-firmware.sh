#!/usr/bin/env bash
#
# install-eden-firmware.sh   (gadget: EdenFirmwareInstall)
#
# Install Nintendo Switch (Eden -- the yuzu successor) firmware + keys into the
# Eden data dir, from a firmware/key drop on the mounted ROMs volume.
#
#   Firmware (a .zip of *.nca)    ->  $EDEN_DATA_DIR/nand/system/Contents/registered/
#   Keys (prod.keys / title.keys / key_retail.bin) -> $EDEN_DATA_DIR/keys/
#
# Shipped in the image at:
#   /etc/cumulus-emu/EdenFirmwareInstall/install-eden-firmware.sh
# (see the "cumulus-emu-canned" derivation in gowbase.nix) and, when a firmware
# zip is dropped in FIRMWARE_DIR, run on first boot by
# /etc/cont-init.d/50-eden-firmware.sh. It is equally safe to run by hand:
#
#   docker exec -u retro <container> \
#     /etc/cumulus-emu/EdenFirmwareInstall/install-eden-firmware.sh
#
# Usage:
#   install-eden-firmware.sh [firmware-zip] [key-file-or-dir ...]
#     - no args   : auto-detect a .zip in FIRMWARE_DIR and keys in KEYS_DIR
#     - with args : install that zip and/or key file(s)/dir (a dir is scanned for
#                   prod.keys / title.keys / key_retail.bin)
#
# Overridable via environment:
#   EDEN_DATA_DIR  (default $HOME/.local/share/eden)
#   FIRMWARE_DIR   (default /ROMs/switch/firmware)
#   KEYS_DIR       (default /ROMs/switch/keys)
#
# Notes:
#   * The image has NO `unzip` (and no `grep`). Extraction uses `7z` (p7zip, on
#     PATH); a /nix/store python3 `zipfile` is the fallback. GNU tar is absent.
#   * The firmware zip may be flat or nested under one top folder; we extract to
#     a temp dir and copy the *.nca files flattened into registered/ -- that is
#     where yuzu/eden expects them (not in a subfolder).
#   * Idempotent: re-running overwrites the same *.nca / key files; a second run
#     after a successful install is a no-op that reports "already present".
#   * Run as the emulator user (retro) so the data dir is owned correctly.
#
set -uo pipefail

HOME="${HOME:-/home/retro}"
EDEN_DATA_DIR="${EDEN_DATA_DIR:-$HOME/.local/share/eden}"
FIRMWARE_DIR="${FIRMWARE_DIR:-/ROMs/switch/firmware}"
KEYS_DIR="${KEYS_DIR:-/ROMs/switch/keys}"
REGISTERED_DIR="$EDEN_DATA_DIR/nand/system/Contents/registered"
KEYS_OUT_DIR="$EDEN_DATA_DIR/keys"
# Temp/log base: $TMPDIR if usable, else a hidden dir in the Eden data dir
# (the club image may have no /tmp, so never assume it exists).
TMP_BASE="${TMPDIR:-}"
if [ -z "$TMP_BASE" ] || [ ! -d "$TMP_BASE" ]; then
  TMP_BASE="${EDEN_DATA_DIR}/.tmp"
fi
mkdir -p "$TMP_BASE" 2>/dev/null || TMP_BASE="${EDEN_DATA_DIR}"
LOG="${TMP_BASE}/.eden-firmware-install.log"
fail=0

die() { echo "ERROR: $*" >&2; exit 1; }

# --- locate an extractor (7z on PATH; /nix/store python3 zipfile fallback) --
extractor=""
py_bin=""
if command -v 7z >/dev/null 2>&1 || [ -x /sbin/7z ]; then
  extractor="7z"
else
  for p in /nix/store/*/bin/python3; do [ -x "$p" ] && py_bin="$p" && break; done
  [ -n "$py_bin" ] && extractor="python3"
fi
[ -n "$extractor" ] || die "no zip extractor (need 7z on PATH, /nix/store/*/bin/python3, or unzip)"

# --- parse positional args: firmware zip, then key file(s)/dir(s) --------
firmware=""
key_args=()
for a in "$@"; do
  case "$a" in
    *.zip|*.ZIP|*.7z) [ -z "$firmware" ] && firmware="$a" ;;
    *) key_args+=("$a") ;;
  esac
done

# --- resolve the firmware zip --------------------------------------------
if [ -n "$firmware" ]; then
  [ -f "$firmware" ] || [ -f "$FIRMWARE_DIR/$firmware" ] || die "firmware not found: $firmware"
  [ -f "$firmware" ] || firmware="$FIRMWARE_DIR/$firmware"
else
  # auto-detect: prefer a *Firmware* zip, else the first .zip in FIRMWARE_DIR
  for f in "$FIRMWARE_DIR"/*.zip "$FIRMWARE_DIR"/*.ZIP "$FIRMWARE_DIR"/*.7z; do
    [ -f "$f" ] || continue
    b="${f##*/}"
    case "$b" in *Firmware*|*firmware*) firmware="$f"; break ;; esac
  done
  [ -n "$firmware" ] || for f in "$FIRMWARE_DIR"/*.zip; do [ -f "$f" ] && firmware="$f" && break; done
fi
have_firmware=0
[ -n "$firmware" ] && [ -f "$firmware" ] && have_firmware=1

# --- key search dirs (explicit args, then KEYS_DIR, then firmware's dir) --
key_dirs=()
for a in "${key_args[@]}"; do [ -d "$a" ] && key_dirs+=("$a"); done
key_dirs+=("$KEYS_DIR")
if [ "$have_firmware" = 1 ]; then
  fwdir="${firmware%/*}"
  if [ "$fwdir" = "$firmware" ]; then fwdir="."; fi
  key_dirs+=("$fwdir")
fi

find_key() { # $1 = base name; prints the first matching path, else returns 1
  local name="$1" d c up
  up="$(echo "$name" | tr 'a-z' 'A-Z')"
  for d in "${key_dirs[@]}"; do
    [ -n "$d" ] && [ -d "$d" ] || continue
    for c in "$d/$name" "$d/$up"; do
      [ -f "$c" ] && { echo "$c"; return 0; }
    done
  done
  return 1
}

# --- report ---------------------------------------------------------------
echo "User        : $(id -un)"
echo "Home        : $HOME"
echo "Data dir    : $EDEN_DATA_DIR"
echo "Registered  : $REGISTERED_DIR"
echo "Keys out    : $KEYS_OUT_DIR"
echo "Extractor   : $extractor"
if [ "$have_firmware" = 1 ]; then
  echo "Firmware    : $firmware"
  echo "Fw size     : $(du -h "$firmware" 2>/dev/null | cut -f1 || true)"
else
  echo "Firmware    : (none found in $FIRMWARE_DIR -- will skip firmware)"
fi
echo

# --- firmware: extract to temp, copy *.nca flattened into registered/ -----
if [ "$have_firmware" = 1 ]; then
  mkdir -p "$REGISTERED_DIR" || die "cannot create $REGISTERED_DIR"
  work="$(mktemp -d "$TMP_BASE/eden-fw.XXXXXX")" || die "mktemp failed"
  trap 'rm -rf "$work"' EXIT
  echo "Extracting firmware (a large zip can take a minute)..."
  if [ "$extractor" = "7z" ]; then
    7z x -y -o"$work" "$firmware" >"$LOG" 2>&1
    rc7z=$?
    # 7z codes: 0=ok, 1..7=warnings (fine), >=8=error
    if [ "$rc7z" -ge 8 ]; then
      echo "ERROR: 7z extraction failed (code $rc7z):" >&2
      tail -n 25 "$LOG" 2>/dev/null || true
      fail=1
    fi
  else
    "$py_bin" - "$firmware" "$work" >"$LOG" 2>&1 <<'PYEOF'
import sys, zipfile
with zipfile.ZipFile(sys.argv[1]) as z:
    z.extractall(sys.argv[2])
PYEOF
    rcpy=$?
    if [ "$rcpy" -ne 0 ]; then
      echo "ERROR: python3 zipfile failed (rc $rcpy):" >&2
      tail -n 25 "$LOG" 2>/dev/null || true
      fail=1
    fi
  fi
  # flatten: copy every *.nca out of the temp tree into registered/
  n=0
  while IFS= read -r -d '' f; do
    cp -f "$f" "$REGISTERED_DIR/" && n=$((n+1))
  done < <(find "$work" -type f \( -name '*.nca' -o -name '*.NCA' \) -print0 2>/dev/null)
  total="$(find "$work" -type f 2>/dev/null | wc -l | tr -d ' ')"
  rm -rf "$work"; trap - EXIT
  if [ "${n:-0}" -ge 1 ]; then
    echo "OK: firmware installed -> $REGISTERED_DIR ($n .nca files)"
  else
    echo "ERROR: no .nca files found in the firmware archive ($total files extracted)" >&2
    fail=1
  fi
else
  echo "(skipping firmware -- no zip in $FIRMWARE_DIR)"
fi

# --- keys: copy prod.keys / title.keys / key_retail.bin into keys/ -------
mkdir -p "$KEYS_OUT_DIR"
copied=""
for a in "${key_args[@]}"; do          # explicit key files from the CLI
  [ -f "$a" ] || continue
  base="${a##*/}"
  cp -f "$a" "$KEYS_OUT_DIR/$base" && copied="$copied $base"
done
for name in prod.keys title.keys key_retail.bin; do
  case "$copied" in *" $name"*) continue ;; esac
  if src="$(find_key "$name")"; then
    cp -f "$src" "$KEYS_OUT_DIR/$name" && copied="$copied $name"
  fi
done
if [ -n "$copied" ]; then
  echo "OK: keys installed -> $KEYS_OUT_DIR($copied)"
else
  echo "WARN: no keys found (searched KEYS_DIR=$KEYS_DIR, arg dirs, firmware dir)" >&2
fi

# --- verification summary -------------------------------------------------
echo
echo "=== verification ==="
nreg="$(find "$REGISTERED_DIR" -maxdepth 1 -type f \( -name '*.nca' -o -name '*.NCA' \) 2>/dev/null | wc -l | tr -d ' ')"
nkeys="$(find "$KEYS_OUT_DIR" -maxdepth 1 -type f 2>/dev/null | wc -l | tr -d ' ')"
echo "registered/ .nca files : ${nreg:-0}"
echo "keys/ files            : ${nkeys:-0}"
for k in prod.keys title.keys key_retail.bin; do
  if [ -f "$KEYS_OUT_DIR/$k" ]; then echo "  present: $k"; else echo "  MISSING: $k"; fi
done

exit "$fail"
