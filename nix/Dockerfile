FROM lscr.io/linuxserver/webtop:ubuntu-mate

RUN apt update && apt install -y xz-utils mesa-vulkan-drivers

WORKDIR /config



# RUN curl -L https://nixos.org/nix/install | sh -s -- --no-daemon
RUN curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | \
  sh -s -- install linux --init none --no-confirm --extra-conf "trusted-users = $(whoami)"

ADD https://github.com/LizardByte/Sunshine/releases/download/v2025.924.154138/sunshine-ubuntu-24.04-amd64.deb sunshine.deb
RUN apt install -y ./sunshine.deb

RUN . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh && \
nix-channel --add https://github.com/nix-community/nixGL/archive/main.tar.gz nixgl && nix-channel --update && \
nix-env -iA nixgl.nixVulkanIntel 

# COPY ./build.sh .
COPY ./*.nix .

RUN . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh && \
# ./build.sh && \
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



RUN rm -rf /config/.cache
