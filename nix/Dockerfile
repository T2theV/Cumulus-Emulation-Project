FROM lscr.io/linuxserver/webtop:ubuntu-mate

RUN apt update && apt install -y xz-utils libssl-dev wget

WORKDIR /config

COPY ./build.sh .
COPY ./dolphin.nix .
COPY ./rpcs3.nix .


RUN wget https://nixos.org/nix/install -O nix.sh
RUN chmod +x nix.sh && chown abc:abc nix.sh && chown -R abc:abc /config

USER abc
RUN ./nix.sh --no-daemon

ENV NIX_PROFILES="/nix/var/nix/profiles/default /config/.nix-profile"
ENV NIX_PATH=/config/.nix-defexpr/channels
ENV NIX_SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
ENV PATH=/config/.nix-profile/bin:$PATH
RUN ./build.sh && nix-build dolphin.nix rpcs3.nix