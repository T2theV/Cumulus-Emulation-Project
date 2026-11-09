# Use an official Ubuntu runtime as a parent image
FROM ubuntu:noble AS pcsx2

# Set environment variables for non-interactive installations
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
  --mount=type=cache,target=/var/lib/apt,sharing=locked \
  apt update && apt --no-install-recommends install -y \
  build-essential ccache clang-17 cmake curl extra-cmake-modules git libasound2-dev libaio-dev libavcodec-dev libavformat-dev libavutil-dev \
  libcurl4-openssl-dev libdbus-1-dev libdecor-0-dev libegl-dev libevdev-dev libfontconfig-dev libfreetype-dev libfuse2 libgtk-3-dev libgudev-1.0-dev \
  libharfbuzz-dev libinput-dev libopengl-dev libpcap-dev libpipewire-0.3-dev libpulse-dev libssl-dev libswresample-dev libswscale-dev libudev-dev \
  libwayland-dev libx11-dev libx11-xcb-dev libxcb1-dev libxcb-composite0-dev libxcb-cursor-dev libxcb-damage0-dev libxcb-glx0-dev libxcb-icccm4-dev \
  libxcb-image0-dev libxcb-keysyms1-dev libxcb-present-dev libxcb-randr0-dev libxcb-render0-dev libxcb-render-util0-dev libxcb-shape0-dev \
  libxcb-shm0-dev libxcb-sync-dev libxcb-util-dev libxcb-xfixes0-dev libxcb-xinput-dev libxcb-xkb-dev libxext-dev libxkbcommon-x11-dev libxrandr-dev \
  lld-17 llvm-17 ninja-build patchelf pkg-config zlib1g-dev ca-certificates unzip

# #SDL3
# RUN --mount=type=bind,from=base-sdl3,source=/app,target=/app,rw \
# cd /app/SDL/build && make install

# Clone the PCSX2 repository
ADD https://github.com/PCSX2/pcsx2.git /opt/pcsx2

RUN /opt/pcsx2/.github/workflows/scripts/linux/build-dependencies-qt.sh /opt/pcsx2/deps

# Set working directory to the cloned repository
WORKDIR /opt/pcsx2/build

# Generate build files with CMake
RUN cmake -G Ninja \
            -DCMAKE_BUILD_TYPE=Release \
            -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=ON \
            -DCMAKE_PREFIX_PATH="/opt/pcsx2/deps" \
            -DCMAKE_C_COMPILER=clang-17 \
            -DCMAKE_CXX_COMPILER=clang++-17 \
            -DCMAKE_EXE_LINKER_FLAGS_INIT="-fuse-ld=lld" \
            -DCMAKE_MODULE_LINKER_FLAGS_INIT="-fuse-ld=lld" \
            -DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
            -DENABLE_SETCAP=OFF \
            -DDISABLE_ADVANCE_SIMD=TRUE \
            ..

# # Build PCSX2 using Ninja
RUN  --mount=type=cache,target=/root/.cache/ccache \
    ninja

