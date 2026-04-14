FROM ghcr.io/linuxserver/baseimage-selkies:ubuntunoble
LABEL org.opencontainers.image.source https://github.com/T2theV/Cumulus-Emulation-Project

RUN apt update && apt install -y --no-install-recommends \
#  build-essential clang-format git cmake gettext libharfbuzz-dev libicu-dev libsdl2-dev libavcodec-dev libavfilter-dev libavformat-dev libavutil-dev libfreeimage-dev libfreetype6-dev libgit2-dev libcurl4-openssl-dev libpugixml-dev libasound2-dev libbluetooth-dev libgl1-mesa-dev libpoppler-cpp-dev \
 xz-utils mesa-vulkan-drivers patch && \
 apt clean && rm -rf /var/lib/apt/lists/*

COPY /root/defaults/autostart_wayland /defaults/autostart_wayland

COPY /root/config /etc/cumulus-emu/config
COPY /root/local /etc/cumulus-emu/local
COPY /root/overall.sh /etc/cumulus-emu/file-init.sh
RUN chmod +x /etc/cumulus-emu/file-init.sh

WORKDIR /nixbuild



#USER abc
#RUN curl -L https://nixos.org/nix/install | sh -s -- --no-daemon --yes
RUN curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | \
  sh -s -- install linux --init none --no-confirm --extra-conf "trusted-users = $(whoami)"

#ESDE
# RUN --mount=type=bind,from=esde-dist,source=/build,target=/build,rw \
#   --mount=type=bind,from=esde-dist,source=/esde,target=/esde,rw \
#   cd /build && make install

#RUN . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh && \
#nix-channel --add https://github.com/nix-community/nixGL/archive/main.tar.gz nixgl && nix-channel --update && \
#nix-env -iA nixgl.nixVulkanIntel 
RUN . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh && \
nix-channel --add https://nixos.org/channels/nixpkgs-unstable unstable && nix-channel --update && \
nix-env -iA unstable.mesa

COPY ./*.sh .
COPY ./*.nix .
COPY ./*.patch .
COPY ./emulators-src.json .
RUN . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh && \
nix-channel --update && \
./localbuild.sh && \
nix-build dolphin.nix flycast.nix pcsx2.nix && \
nix-build rmg.nix rpcs3.nix && \
nix-build xemu.nix xenia-canary.nix && \
nix-build eden.nix && \
# #RUN . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh && \
nix-env -i -f ./eden.nix && \
nix-env -i -f ./dolphin.nix && \
nix-env -i -f ./flycast.nix && \
nix-env -i -f ./pcsx2.nix && \
nix-env -i -f ./rmg.nix && \
nix-env -i -f ./rpcs3.nix && \
nix-env -i -f ./xemu.nix && \
nix-env -i -f ./xenia-canary.nix && \
nix-store --gc

RUN patch /usr/share/selkies/selkies-dashboard/src/universalTouchGamepad.js /nixbuild/universalgamepad.patch
RUN patch /usr/share/selkies/selkies-dashboard-wish/src/universalTouchGamepad.js /nixbuild/universalgamepad.patch

ENV PIXELFLUX_WAYLAND=true

RUN rm -rf /config/.cache

WORKDIR /config
