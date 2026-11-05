#!/bin/bash
# /opt/gow/prelaunch-controllers.sh — hotplug-emu prelaunch (wiring A)
#
# Sibling of launch-comp.sh. GOW-managed files (launch-comp.sh, startup.sh,
# startup-app.sh) are untouched — they live in /nix/store via symlinks.
#
# This script is the app-container entrypoint. It:
#   1. ensures the app home exists (we must not create it root-owned after
#      GOW expects to own it — chown to the GOW default app user 1000)
#   2. starts the hotplug-emu listener daemon (idempotent)
#   3. one-shot applies the current controller state to emulator configs
#   4. hands off to the standard GOW startup chain (as the app user)
set -e
source /opt/gow/bash-lib/utils.sh

HPEMU=/usr/bin/hotplug-emu
HPEMU_HOME="${HPEMU_HOME:-/home/retro}"
RUNDIR=/run/hotplug-emu
mkdir -p "$RUNDIR"
export HPEMU_HOME

# 1) app home: if missing, create it owned by the GOW default app user
if [ ! -d "$HPEMU_HOME" ]; then
  mkdir -p "$HPEMU_HOME"
  chown -R 1000:1000 "$HPEMU_HOME"
fi

# 2) start daemon if not already running
if [ -f "$RUNDIR/pid" ] && kill -0 "$(cat "$RUNDIR/pid" 2>/dev/null)" 2>/dev/null; then
  gow_log "hotplug-emu: daemon already running (pid $(cat "$RUNDIR/pid"))"
else
  nohup "$HPEMU" daemon >> "$RUNDIR/hotplug-emu.log" 2>&1 &
  echo $! > "$RUNDIR/pid"
  gow_log "hotplug-emu: daemon started (pid $!)"
fi

# 3) one-shot apply of current controller state (idempotent; never fatal)
if ! "$HPEMU" apply; then
  gow_log "hotplug-emu: prelaunch apply failed (continuing)"
fi

# 4) hand off to the standard GOW chain, as the app user
if command -v gosu >/dev/null 2>&1; then
  exec gosu "${UNAME:-retro}" /opt/gow/startup.sh
else
  exec /opt/gow/startup.sh
fi
