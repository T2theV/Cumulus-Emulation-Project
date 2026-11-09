FROM ubuntu:noble

ENV DEBIAN_FRONTEND=noninteractive 
ENV TZ="Etc/UTC" 

RUN apt-get update && apt-get install -y \
    git build-essential cmake libsdl2-dev libepoxy-dev \
    libpixman-1-dev libgtk-3-dev libssl-dev libsamplerate0-dev \
    libpcap-dev ninja-build python3-yaml python3-pip libslirp-dev libvulkan-dev
ADD https://github.com/xemu-project/xemu.git /xemu
WORKDIR /xemu
RUN ./build.sh