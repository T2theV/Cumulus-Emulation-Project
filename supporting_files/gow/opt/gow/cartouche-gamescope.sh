#!/bin/sh
# cartouche-gamescope.sh — launch cartouche under gamescope (GOW-style).
# CARTOUCHE_CONFIG + CARTOUCHE_GAMES_DIR must be exported here: they are NOT
# in the container image's global env, so without them cartouche scans the
# default `roms/` beside the binary (empty in the Nix store) and has no
# players config.
export CARTOUCHE_CONFIG=/home/retro/.config/cartouche/cartouche.conf
export CARTOUCHE_GAMES_DIR=/ROMs
W=${GAMESCOPE_WIDTH:-1920}; H=${GAMESCOPE_HEIGHT:-1080}; R=${GAMESCOPE_REFRESH:-60}
M=${GAMESCOPE_MODE:--f}
exec gamescope $M -W "$W" -H "$H" -w "$W" -h "$H" -r "$R" --expose-wayland -- cartouche
