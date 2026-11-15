FROM ubuntu:noble as base

ENV DEBIAN_FRONTEND=noninteractive 
ENV TZ="Etc/UTC" 

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt update && apt-get --no-install-recommends install -y \git cmake g++ make libasound2-dev \
    libpulse-dev libjack-jackd2-dev libgl1-mesa-dev \
    libdbus-1-dev libudev-dev libssl-dev \
    libxinerama-dev libxcursor-dev libxrandr-dev \
    libxi-dev libvulkan-dev \
    libibus-1.0-dev libudev-dev libwayland-dev \
    libegl1-mesa-dev libgles2-mesa-dev \
    libusb-dev libpipewire-0.3-dev libwayland-dev libdecor-0-dev liburing-dev

WORKDIR /app

# Clone SDL3 repository
ADD https://github.com/libsdl-org/SDL.git /app/SDL

# Build SDL3 using CMake
WORKDIR /app/SDL
RUN mkdir build && cd build && \
    cmake -DCMAKE_INSTALL_PREFIX=/usr/local .. && \
    make -j${nproc}


