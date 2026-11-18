#!/bin/bash

set -e
source /opt/gow/bash-lib/utils.sh
source /opt/gow/launch-comp.sh

# Cartouche (ROM cartridge launcher) — replaces pegasus-frontend in this
# test image. Launched via cartouche-gamescope.sh so it runs under gamescope
# (RUN_GAMESCOPE=1) with the CARTOUCHE_CONFIG + CARTOUCHE_GAMES_DIR env
# exports it needs (not in the image's global env).
sh /opt/gow/cartouche-gamescope.sh
#launcher pegasus-fe -platform xcb   # replaced by cartouche (test branch)
#launcher RMG
#launcher foot
#foot

