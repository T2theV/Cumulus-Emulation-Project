#FROM lscr.io/linuxserver/webtop:ubuntu-mate
FROM ghcr.io/t2thev/t2thev-selkies:latest

RUN apt update && apt install -y xz-utils mesa-vulkan-drivers

WORKDIR /config



# RUN curl -L https://nixos.org/nix/install | sh -s -- --no-daemon
RUN curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | \
  sh -s -- install linux --init none --no-confirm --extra-conf "trusted-users = $(whoami)"

ADD https://github.com/LizardByte/Sunshine/releases/download/v2025.924.154138/sunshine-ubuntu-24.04-amd64.deb sunshine.deb
RUN apt install -y ./sunshine.deb

#Emulation Station
#ADD https://

RUN . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh && \
nix-channel --add https://github.com/nix-community/nixGL/archive/main.tar.gz nixgl && nix-channel --update && \
nix-env -iA nixgl.nixVulkanIntel 

COPY ./*.sh .
COPY ./*.nix .
COPY ./emulators-src.json .
RUN . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh && \
nix-channel --update && \
./localbuild.sh && \
nix-build dolphin.nix flycast.nix pcsx2.nix && \
nix-build rmg.nix rpcs3.nix && \
nix-build xemu.nix xenia-canary.nix

RUN . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh && \
nix-env -i -f ./dolphin.nix && \
nix-env -i -f ./flycast.nix && \
nix-env -i -f ./pcsx2.nix && \
nix-env -i -f ./rmg.nix && \
nix-env -i -f ./rpcs3.nix && \
nix-env -i -f ./xemu.nix && \
nix-env -i -f ./xenia-canary.nix

RUN <<EOF
  echo "alias dolphin-emu='nixVulkanIntel dolphin-emu'" >> .bashrc
  echo "alias flycast='nixVulkanIntel flycast'" >> .bashrc
  echo "alias pcsx2-qt='nixVulkanIntel pcsx2-qt'" >> .bashrc
  echo "alias rpcs3='nixVulkanIntel rpcs3'">> .bashrc
  echo "alias RMG='nixVulkanIntel RMG'" >> .bashrc
  echo "alias xenia_canary='nixVulkanIntel xenia_canary'" >> .bashrc
EOF

ENV PIXELFLUX_WAYLAND=true

RUN rm -rf /config/.cache
