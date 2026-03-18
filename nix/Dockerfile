#FROM lscr.io/linuxserver/webtop:ubuntu-mate
FROM ghcr.io/t2thev/t2thev-selkies:latest

RUN apt update && apt install -y --no-install-recommends \
 build-essential clang-format git cmake gettext libharfbuzz-dev libicu-dev libsdl2-dev libavcodec-dev libavfilter-dev libavformat-dev libavutil-dev libfreeimage-dev libfreetype6-dev libgit2-dev libcurl4-openssl-dev libpugixml-dev libasound2-dev libbluetooth-dev libgl1-mesa-dev libpoppler-cpp-dev \
 xz-utils mesa-vulkan-drivers && \
 apt clean && rm -rf /var/lib/apt/lists/*

ADD /root/defaults/autostart_wayland /defaults/autostart_wayland

WORKDIR /config


#USER abc
#RUN curl -L https://nixos.org/nix/install | sh -s -- --no-daemon --yes
# RUN curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | \
#   sh -s -- install linux --init none --no-confirm --extra-conf "trusted-users = $(whoami)"

#ESDE
RUN --mount=type=bind,from=esde-dist,source=/build,target=/build,rw \
  --mount=type=bind,from=esde-dist,source=/esde,target=/esde,rw \
  cd /build && make install

#RUN . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh && \
#nix-channel --add https://github.com/nix-community/nixGL/archive/main.tar.gz nixgl && nix-channel --update && \
#nix-env -iA nixgl.nixVulkanIntel 
# RUN . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh && \
# nix-channel --add https://nixos.org/channels/nixpkgs-unstable unstable && nix-channel --update && \
# nix-env -iA unstable.mesa

# COPY ./*.sh .
# COPY ./*.nix .
# COPY ./*.patch .
# COPY ./emulators-src.json .
# RUN . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh && \
# nix-channel --update && \
# ./localbuild.sh && \
# nix-build dolphin.nix flycast.nix pcsx2.nix && \
# nix-build rmg.nix rpcs3.nix && \
# nix-build xemu.nix xenia-canary.nix && \
# nix-build eden.nix && \
# #RUN . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh && \
# nix-env -i -f ./eden.nix && \
# nix-env -i -f ./dolphin.nix && \
# nix-env -i -f ./flycast.nix && \
# nix-env -i -f ./pcsx2.nix && \
# nix-env -i -f ./rmg.nix && \
# nix-env -i -f ./rpcs3.nix && \
# nix-env -i -f ./xemu.nix && \
# nix-env -i -f ./xenia-canary.nix
# && \
#nix-store --gc

#RUN <<EOF
#  echo "alias eden='nixVulkanIntel eden'" >> .bashrc
#  echo "alias dolphin-emu='nixVulkanIntel dolphin-emu'" >> .bashrc
#  echo "alias flycast='nixVulkanIntel flycast'" >> .bashrc
#  echo "alias pcsx2-qt='nixVulkanIntel pcsx2-qt'" >> .bashrc
#  echo "alias rpcs3='QT_QPA_PLATFORM=xcb nixVulkanIntel rpcs3'">> .bashrc
#  echo "alias RMG='nixVulkanIntel RMG'" >> .bashrc
#  echo "alias xenia_canary='nixVulkanIntel xenia_canary'" >> .bashrc
#EOF

ADD https://github.com/flyinghead/flycast/releases/download/v2.6/flycast-x86_64.AppImage flycast.AppImage
RUN chmod +x flycast.AppImage && flycast.AppImage --appimage-extract

ENV PIXELFLUX_WAYLAND=true

RUN rm -rf /config/.cache

