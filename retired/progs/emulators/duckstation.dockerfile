FROM ubuntu:noble AS duckstation

# Set environment variables for non-interactive installations
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
  --mount=type=cache,target=/var/lib/apt,sharing=locked \
  apt update && apt --no-install-recommends install -y \
  git clang llvm lld libxcb-util0-dev build-essential curl cmake libsdl2-dev libepoxy-dev \
  libpixman-1-dev libgtk-3-dev libssl-dev libsamplerate0-dev \
  libpcap-dev ninja-build python3-yaml python3-pip libslirp-dev libvulkan-dev \
  '^libxcb.*-dev' libx11-xcb-dev libglu1-mesa-dev libxrender-dev libxi-dev libxkbcommon-dev libxkbcommon-x11-dev libcurl4-openssl-dev \
  extra-cmake-modules qttools5-dev-tools

# Install aqtinstall
RUN --mount=type=cache,target=/root/.cache/pip python3 -m pip install --break-system-packages aqtinstall
RUN aqt install-qt linux desktop 6.8.2 -O /usr/local/Qt -m qtimageformats qtmultimedia
RUN <<EOT bash
        echo "/usr/local/Qt/6.8.2/gcc_64/lib" > /etc/ld.so.conf.d/qt.conf
                ldconfig
                chown -R root:root /usr/local/Qt
EOT

  # Clone the Duckstation repository
ADD https://github.com/stenzek/duckstation.git /duckstation 

RUN mkdir /duckstation/build

# Change to the build directory
WORKDIR /duckstation/build

RUN ../scripts/deps/build-dependencies-linux.sh -system-qt deps
# Build Duckstation
RUN cmake .. \ 
-DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ -DCMAKE_EXE_LINKER_FLAGS_INIT="-fuse-ld=lld" \
-DCMAKE_MODULE_LINKER_FLAGS_INIT="-fuse-ld=lld" \
-DCMAKE_SHARED_LINKER_FLAGS_INIT="-fuse-ld=lld" \
-DCMAKE_PREFIX_PATH="/duckstation/build/deps;/usr/local/Qt/6.8.2/gcc_64/lib/cmake" \
-G Ninja -DCMAKE_BUILD_TYPE=Release \
-DCMAKE_INTERPROCEDURAL_OPTIMIZATION=ON \
&& ninja
