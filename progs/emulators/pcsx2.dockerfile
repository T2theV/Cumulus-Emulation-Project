# Use an official Ubuntu runtime as a parent image
FROM ubuntu:noble AS pcsx2

# Set environment variables for non-interactive installations
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
  --mount=type=cache,target=/var/lib/apt,sharing=locked \
  apt update && apt --no-install-recommends install -y \
    build-essential \
    cmake \
    git \
    libaio-dev \
    libasound2-dev \
    libpulse-dev \
    libaudio-dev \
    libjack-dev \
    libsndio-dev \
    libbz2-dev \
    libc6-dev \
    libelf-dev \
    libevdev-dev \
    libgl1-mesa-dev \
    libgtk-3-dev \
    libinput-dev \
    libopenal-dev \
    libsdl2-dev \
    libusb-1.0-0-dev \
    libvulkan-dev \
    ninja-build \
    pkg-config \
    qtbase5-dev-tools \
    qttools5-dev-tools \
    wget \
    zlib1g-dev \
    liblz4-dev \
    libpipewire-0.3-dev \
    libwayland-dev \
    libdecor-0-dev \
    liburing-dev \
    libshaderc1 \
    glslc \
    libshaderc-dev \
    build-essential clang cmake curl extra-cmake-modules git libasound2-dev libaio-dev libavcodec-dev libavformat-dev libavutil-dev libcurl4-openssl-dev libdbus-1-dev libdecor-0-dev libegl-dev libevdev-dev libfontconfig-dev libfreetype-dev libgtk-3-dev libgudev-1.0-dev libharfbuzz-dev libinput-dev libopengl-dev libpcap-dev libpipewire-0.3-dev libpulse-dev libssl-dev libswresample-dev libswscale-dev libudev-dev libwayland-dev libx11-dev libx11-xcb-dev libxcb1-dev libxcb-composite0-dev libxcb-cursor-dev libxcb-damage0-dev libxcb-glx0-dev libxcb-icccm4-dev libxcb-image0-dev libxcb-keysyms1-dev libxcb-present-dev libxcb-randr0-dev libxcb-render0-dev libxcb-render-util0-dev libxcb-shape0-dev libxcb-shm0-dev libxcb-sync-dev libxcb-util-dev libxcb-xfixes0-dev libxcb-xinput-dev libxcb-xkb-dev libxext-dev libxkbcommon-x11-dev libxrandr-dev lld llvm ninja-build pkg-config zlib1g-dev

#SDL3
RUN --mount=type=bind,from=base-sdl3,source=/app,target=/app,rw \
cd /app/SDL/build && make install

# Clone the PCSX2 repository
ADD https://github.com/PCSX2/pcsx2.git /opt/pcsx2

# Set working directory to the cloned repository
WORKDIR /opt/pcsx2/build

# Generate build files with CMake
# RUN cmake -G Ninja -DCMAKE_CXX_COMPILER_LAUNCHER=ccache -DCMAKE_BUILD_TYPE=Release -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=ON ..

# # Build PCSX2 using Ninja
# RUN  --mount=type=cache,target=/root/.cache/ccache \
#     ninja pcsx2 -j${nproc}

