FROM lscr.io/linuxserver/webtop:ubuntu-mate

RUN apt update && apt install -y xz-utils

WORKDIR /config

COPY ./build.sh .
COPY ./dolphin.nix .
COPY ./rpcs3.nix .


RUN curl -L https://nixos.org/nix/install | sh -s -- --daemon


ENV NIX_PROFILES="/nix/var/nix/profiles/default /root/.nix-profile"
ENV NIX_PATH=/root/.nix-defexpr/channels
ENV NIX_SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
ENV PATH=/root/.nix-profile/bin:$PATH
RUN ./build.sh && nix-build dolphin.nix rpcs3.nix