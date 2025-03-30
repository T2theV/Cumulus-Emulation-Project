# Use an official Ubuntu runtime as a parent image
FROM ubuntu:noble AS flycast

# Set environment variables for non-interactive installations
ENV DEBIAN_FRONTEND=noninteractive 

# Install dependencies
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
  --mount=type=cache,target=/var/lib/apt,sharing=locked \
  apt update && apt --no-install-recommends install -y \
  build-essential curl cmake libsdl2-dev libepoxy-dev \
  libpixman-1-dev libgtk-3-dev libssl-dev libsamplerate0-dev \
  libpcap-dev ninja-build python3-yaml python3-pip libslirp-dev libvulkan-dev

# Clone the Flycast repository
ADD https://github.com/flyinghead/flycast.git /flycast

RUN mkdir /flycast/build
# Change to the build directory
WORKDIR /flycast/build

# Build Flycast
RUN cmake .. && make -j$(nrpoc)