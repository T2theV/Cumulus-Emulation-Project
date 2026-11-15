# syntax=docker/dockerfile:latest
  # ==================================================
  # ==      ==============  ================  =====  =
  # =  ====  =============  ================  =====  =
  # =  ====  ===  ========  ================  =====  =
  # =  ====  ==    =======  =====  =  ==  ==  =====  =
  # =  ====  ===  ========    ===  =  ======  ===    =
  # =  ====  ===  ========  =  ==  =  ==  ==  ==  =  =
  # =  =  =  ===  ========  =  ==  =  ==  ==  ==  =  =
  # =  ==    ===  ========  =  ==  =  ==  ==  ==  =  =
  # ==      ====   =======    ====    ==  ==  ===    =
  # ==================================================
  
  #Qt build and install
  FROM debian AS qt-base
  #install dependencies
  RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
  --mount=type=cache,target=/var/lib/apt,sharing=locked \
  apt update && apt-get --no-install-recommends install -y \
  libfontconfig1-dev \
  libfreetype6-dev \
  libx11-dev \
  libx11-xcb-dev \
  libxext-dev \
  libxfixes-dev \
  libxi-dev \
  libxrender-dev \
  libxcb1-dev \
  libxcb-cursor-dev \
  libxcb-glx0-dev \
  libxcb-keysyms1-dev \
  libxcb-image0-dev \
  libxcb-shm0-dev \
  libxcb-icccm4-dev \
  libxcb-sync-dev \
  libxcb-xfixes0-dev \
  libxcb-shape0-dev \
  libxcb-randr0-dev \
  libxcb-render-util0-dev \
  libxcb-util-dev \
  libxcb-xinerama0-dev \
  libxcb-xkb-dev \
  libxkbcommon-dev \
  libxkbcommon-x11-dev \
  xz-utils \
  build-essential \
  cmake \
  python3 \
  ninja-build \
  libdrm-dev \
  libgles2-mesa-dev \
  ccache

  WORKDIR /
  #download and extract
  ADD https://download.qt.io/archive/qt/6.8/6.8.1/single/qt-everywhere-src-6.8.1.tar.xz /qt.tar.xz
  RUN tar xf qt.tar.xz && mv /qt-everywhere-src-6.8.1 /qt6
  #install
  WORKDIR /qt6
  RUN --mount=type=cache,id=qtcache,target=/root/.cache/ccache \
    mkdir qt6_build && cd qt6_build && ../configure -- -D CMAKE_C_COMPILER_LAUNCHER=ccache -D CMAKE_CXX_COMPILER_LAUNCHER=ccache && cmake --build . --parallel $(nproc)

  # FROM scratch AS qt-dist
  # COPY --from=qt-base /qt-everywhere-src-6.6.3  .