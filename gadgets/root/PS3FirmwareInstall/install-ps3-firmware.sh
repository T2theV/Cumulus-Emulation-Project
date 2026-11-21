#!/usr/bin/env bash
#
# install-ps3-firmware.sh   (gadget: PS3FirmwareInstall)
#
# Install PS3 firmware into RPCS3 from the local firmware drop in /ROMs/bios/ps3/.
#
# Shipped in the image at:
#   /etc/cumulus-emu/PS3FirmwareInstall/install-ps3-firmware.sh
# (see the "cumulus-emu-canned" derivation in gowbase.nix) and invoked on first
# boot by /etc/cont-init.d/45-ps3-firmware.sh.
#
# Usage:
#   install-ps3-firmware.sh [firmware-file]
#     - no arg : auto-detect (prefer PS3UPDAT.PUP, then PS3UPDAT.1.PUP, else the
#                first non-"_old" *.pup/*.PUP in FIRMWARE_DIR)
#     - with arg: install that file (a path, or a bare filename in FIRMWARE_DIR)
#
# Run it as the emulator user (the user that owns the RPCS3 data dir):
#   docker exec -u retro <container> \
#     /etc/cumulus-emu/PS3FirmwareInstall/install-ps3-firmware.sh
#
# Notes:
#   * RPCS3's CLI does the real work:  rpcs3 --headless --installfw <file>
#     (plain --installfw / --no-gui HANG in a display-less container).
#   * This nix build exits 134 with a benign "Verification failed / process
#     teardown" assertion after the install completes, so we do NOT trust the
#     exit code: we VERIFY the data dir instead.
#   * The install is bounded (MAX_WAIT) and killed if it overruns -> no hang.
#   * RPCS3 refuses a data dir under /tmp, so this must target the real home.
#
set -uo pipefail

FIRMWARE_DIR="/ROMs/bios/ps3"
MAX_WAIT="${MAX_WAIT:-180}"                 # seconds to allow the install
HOME="${HOME:-/home/retro}"
DATA_DIR="${RPCS3_DATA_DIR:-$HOME/.config/rpcs3}"
LOG="/tmp/rpcs3-install.log"

die() { echo "ERROR: $*" >&2; exit 1; }

# --- locate the rpcs3 binary -----------------------------------------------
rpcs3_bin="$(command -v rpcs3 || true)"
[ -n "$rpcs3_bin" ] || rpcs3_bin="$( [ -x /sbin/rpcs3 ] && echo /sbin/rpcs3 || true)"
[ -n "$rpcs3_bin" ] || rpcs3_bin="$(ls -1d /nix/store/*/bin/rpcs3 /nix/store/*/bin/.rpcs3-wrapped 2>/dev/null | head -1 || true)"
[ -n "$rpcs3_bin" ] || die "rpcs3 not found (PATH, /sbin, or /nix/store)"

# --- resolve the firmware file -------------------------------------------
firmware="${1:-}"
if [ -n "$firmware" ]; then
  [ -f "$firmware" ] || [ -f "$FIRMWARE_DIR/$firmware" ] || die "firmware not found: $firmware"
  [ -f "$firmware" ] || firmware="$FIRMWARE_DIR/$firmware"
else
  # auto-detect: canonical names first, else first non-_-old pup (no grep in image)
  for cand in "PS3UPDAT.PUP" "PS3UPDAT.1.PUP"; do
    [ -f "$FIRMWARE_DIR/$cand" ] && firmware="$FIRMWARE_DIR/$cand" && break
  done
  if [ -z "$firmware" ]; then
    for f in "$FIRMWARE_DIR"/*.pup "$FIRMWARE_DIR"/*.PUP; do
      [ -f "$f" ] || continue
      b="${f##*/}"
      case "$b" in *_old*) continue ;; esac
      firmware="$f"; break
    done
  fi
fi
[ -n "$firmware" ] && [ -f "$firmware" ] || die "no firmware file found in $FIRMWARE_DIR"

# --- report ---------------------------------------------------------------
echo "User      : $(id -un)"
echo "Home      : $HOME"
echo "rpcs3     : $rpcs3_bin"
echo "Firmware  : $firmware"
size="$(du -h "$firmware" 2>/dev/null | cut -f1 || true)"
echo "Size      : ${size:-?}"
echo "Data dir  : $DATA_DIR"
echo
echo "Installing firmware -> $DATA_DIR/dev_flash  (max ${MAX_WAIT}s)..."
echo

# --- install (bounded; exit 134 at teardown is expected in this build) -----
"$rpcs3_bin" --headless --installfw "$firmware" >"$LOG" 2>&1 &
pid=$!
i=0
while kill -0 "$pid" 2>/dev/null && [ "$i" -lt "$MAX_WAIT" ]; do sleep 1; i=$((i+1)); done
if kill -0 "$pid" 2>/dev/null; then
  echo "WARNING: still running after ${MAX_WAIT}s; killing pid $pid" >&2
  kill -9 "$pid" 2>/dev/null
fi
wait "$pid" 2>/dev/null
rc=$?

echo "rpcs3 exit code: $rc   (134 = benign teardown assertion in this build)"
echo "--- install log (tail) ---"
tail -n 20 "$LOG" 2>/dev/null || true
echo "-----------------------------"
echo

# --- verify firmware actually landed in the data dir ---------------------
dev_flash="$DATA_DIR/dev_flash"
ok=1
if [ -d "$dev_flash/vsh" ] && [ -d "$dev_flash/sys" ]; then
  n="$(find "$dev_flash" -type f 2>/dev/null | wc -l | tr -d ' ')"
  if [ "${n:-0}" -ge 100 ]; then
    ok=0
    echo "OK: firmware installed -> $dev_flash ($n files)"
  else
    echo "ERROR: dev_flash present but only ${n:-0} files (looks incomplete)" >&2
  fi
else
  echo "ERROR: firmware not installed (no $dev_flash/vsh or /sys)" >&2
fi
exit "$ok"
