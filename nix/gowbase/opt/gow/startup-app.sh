#!/bin/bash

set -e
source /opt/gow/launch-comp.sh
export XDG_DATA_DIRS=/share:$XDG_DATA_DIRS
#export LD_PRELOAD=/lib/libxcb-cursor.so
#foot
#export XDG_SESSION_TYPE=x11
#unset WAYLAND_DISPLAY
#dolphin-emu
foot
