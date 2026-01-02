FROM ghcr.io/linuxserver/baseimage-selkies:ubuntunoble

RUN apt update && apt install -y xz-utils libssl-dev wget

WORKDIR /config
RUN wget https://nixos.org/nix/install -O nix.sh
RUN chmod +x nix.sh && ./nix.sh --daemon

COPY ./build.sh .
COPY ./dolphin.nix .
COPY ./rpcs3.nix .

ENV NIX_PROFILES="/nix/var/nix/profiles/default /root/.nix-profile"
ENV NIX_PATH=/root/.nix-defexpr/channels
ENV NIX_SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
ENV PATH=/root/.nix-profile/bin:$PATH
RUN . /root/.nix-profile/etc/profile.d/nix.sh && ./build.sh && nix-build dolphin.nix rpcs3.nix