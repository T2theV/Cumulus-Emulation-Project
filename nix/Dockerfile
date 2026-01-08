FROM lscr.io/linuxserver/webtop:ubuntu-mate

RUN apt update && apt install -y xz-utils

WORKDIR /config

COPY ./build.sh .
COPY ./dolphin.nix .
COPY ./rpcs3.nix .


# RUN curl -L https://nixos.org/nix/install | sh -s -- --no-daemon
RUN curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | \
  sh -s -- install linux --init none --no-confirm --extra-conf "trusted-users = $(whoami)" 
RUN  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh && \
./build.sh && nix-build dolphin.nix rpcs3.nix