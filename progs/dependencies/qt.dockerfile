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
  ccache \
  git \
  ca-certificates \
  perl

  WORKDIR /
  #download and extract
  RUN git clone --branch v6.7.3 https://code.qt.io/qt/qt5.git /qt
  WORKDIR qt
  #install
  RUN --mount=type=cache,id=qtcache,target=/root/.cache/ccache \
<<EOT bash
  perl init-repository --module-subset  qtbase,qtmultimedia,qtdeclarative,qtsvg,qtshadertools  
  mkdir qt6_build
  cd qt6_build
  ../configure -submodules qtbase,qtmultimedia,qtdeclarative,qtsvg,qtshadertools -- -D CMAKE_C_COMPILER_LAUNCHER=ccache -D CMAKE_CXX_COMPILER_LAUNCHER=ccache
  cmake --build . --parallel $(nproc)
  find . -name "*.o" -type f -delete
EOT

  FROM scratch AS qt-dist
  COPY --from=qt-base /qt  .