#!/bin/bash

# Enable Nvidia GPU support if detected
if which nvidia-smi; then
  export LIBGL_KOPPER_DRI2=1
  export MESA_LOADER_DRIVER_OVERRIDE=zink
  export GALLIUM_DRIVER=zink
fi

sudo chown root:abc /dev/uinput
sudo chmod 660 /dev/uinput
sunshine &

# Disable compositing
setterm blank 0
setterm powerdown 0
gsettings set org.mate.Marco.general compositing-manager false
gsettings set org.mate.screensaver idle-activation-enabled false
gsettings set org.mate.screensaver lock-enabled false

# Launch DE
/usr/bin/mate-session > /dev/null 2>&1
