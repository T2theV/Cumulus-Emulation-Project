# Use an official Ubuntu image as the base image
FROM ubuntu:latest

# Set environment variables to prevent interactive prompts during package installs
ENV DEBIAN_FRONTEND=noninteractive

# Update the package list and install necessary dependencies for Rosalie's Mupen GUI
RUN apt-get update && \
    apt-get install -y \
    cmake \
    libhidapi-dev \
    libsamplerate0-dev \
    libspeex-dev \
    libminizip-dev \
    libsdl2-dev \
    libsdl2-net-dev \
    libfreetype6-dev \
    libgl1-mesa-dev \
    libglu1-mesa-dev \
    pkg-config \
    zlib1g-dev \
    binutils-dev \
    libspeexdsp-dev \
    qt6-base-dev \
    libqt6svg6-dev \
    libvulkan-dev \
    build-essential \
    nasm \
    git \
    zip \
    ninja-build \
    python3-pip 

 # Install aqtinstall
RUN --mount=type=cache,target=/root/.cache/pip python3 -m pip install --break-system-packages aqtinstall

# Clone the Rosalie's Mupen GUI repository
ADD https://github.com/Rosalie241/RMG.git /RMG

# Change directory to the cloned repository
WORKDIR /RMG

 # Install Qt using aqtinstall
RUN aqt install-qt linux desktop 6.8.2 -O /usr/local/Qt -m qtmultimedia qtwebsockets

# RUN ./Source/Script/Build.sh Release

# # Build and install Rosalie's Mupen GUI with CMake prefix path
RUN mkdir build && \
     cd build && \
    cmake .. -DCMAKE_PREFIX_PATH=/usr/local/Qt/6.8.2/gcc_64/lib/cmake -DCMAKE_BUILD_TYPE="Release" -DPORTABLE_INSTALL="OFF" -G "Ninja" && \ 
    ninja

