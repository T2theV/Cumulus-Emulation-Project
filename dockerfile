# syntax=docker/dockerfile:1



# ====================================================================
# =      ===============  =====  =======      ========================
# =  ===  ==============  =====  =======  ===  =======================
# =  ====  =============  =====  =======  ====  ======================
# =  ===  ===  =  ==  ==  =====  =======  ===  ====   ====   ====   ==
# =      ====  =  ======  ===    =======      ====  =  ==  =  ==  =  =
# =  ===  ===  =  ==  ==  ==  =  =======  ===  ======  ===  ====     =
# =  ====  ==  =  ==  ==  ==  =  =======  ====  ===    ====  ===  ====
# =  ===  ===  =  ==  ==  ==  =  =======  ===  ===  =  ==  =  ==  =  =
# =      =====    ==  ==  ===    =======      =====    ===   ====   ==
# ====================================================================

FROM ubuntu:jammy AS build-base01
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
  --mount=type=cache,target=/var/lib/apt,sharing=locked \
  apt update && apt-get --no-install-recommends install -y \
  build-essential \
  git \
  cmake \
  ffmpeg \
  libavcodec-dev \
  libavformat-dev \
  libavutil-dev \
  libswscale-dev \
  libevdev-dev \
  libusb-1.0-0-dev \
  libxrandr-dev \
  libxi-dev \
  libpangocairo-1.0-0 \
  qt6-base-private-dev \
  libqt6svg6-dev \
  libbluetooth-dev \
  libasound2-dev \
  libpulse-dev \
  libgl1-mesa-dev \
  libcurl4-openssl-dev \
  libopenal-dev \
  libglew-dev \
  zlib1g-dev \
  libedit-dev \
  libvulkan-dev \
  libudev-dev \
  libsdl2-2.0 \
  libsdl2-dev \
  libjack-dev \
  libsndio-dev \
  clang-format \
  libavfilter-dev \
  libfreeimage-dev \
  libfreetype6-dev \
  libgit2-dev \
  libpugixml-dev \
  libpoppler-cpp-dev \
  ca-certificates \
  gettext \
  libharfbuzz-dev \
  libicu-dev \
  ccache

  RUN ccache -M 0 --set-config=compiler_check=content --set-config=sloppiness=include_file_ctime,include_file_mtime



 
# ===================================================================================
# =       ==========  =========  =====================      ===============  =====  =
# =  ====  =========  =========  =====================  ===  ==============  =====  =
# =  ====  =========  =========  =====================  ====  =============  =====  =
# =  ====  ===   ===  ==    ===  =====  ==  = ========  ===  ===  =  ==  ==  =====  =
# =  ====  ==     ==  ==  =  ==    =======     =======      ====  =  ======  ===    =
# =  ====  ==  =  ==  ==  =  ==  =  ==  ==  =  =======  ===  ===  =  ==  ==  ==  =  =
# =  ====  ==  =  ==  ==    ===  =  ==  ==  =  =======  ====  ==  =  ==  ==  ==  =  =
# =  ====  ==  =  ==  ==  =====  =  ==  ==  =  =======  ===  ===  =  ==  ==  ==  =  =
# =       ====   ===  ==  =====  =  ==  ==  =  =======      =====    ==  ==  ===    =
# ===================================================================================
  
  #Dolphin build
  FROM build-base01 AS dolphinemu
  ADD https://github.com/dolphin-emu/dolphin.git /dolphin
  WORKDIR /dolphin
  
  RUN --mount=type=cache,id=dolphincache,target=/root/.cache/ccache \
    mkdir build && cd build && cmake -D CMAKE_C_COMPILER_LAUNCHER=ccache -D CMAKE_CXX_COMPILER_LAUNCHER=ccache .. && make -j$(nproc)

  FROM scratch AS dolphin-dist
  COPY --from=dolphinemu /dolphin .

 
  
  # ADD https://github.com/llvm/llvm-project.git#llvmorg-17.0.1 /llvm
  # WORKDIR /llvm
  # RUN cmake -S llvm -B build -G "Unix Makefiles" -D CMAKE_INSTALL_PREFIX=/usr/local -DCMAKE_BUILD_TYPE=Release && cd build && make -j $(nproc) && make install

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
  ADD https://download.qt.io/archive/qt/6.6/6.6.3/single/qt-everywhere-src-6.6.3.tar.xz /qt.tar.xz
  RUN tar xf qt.tar.xz
  #install
  WORKDIR /qt-everywhere-src-6.6.3
  RUN --mount=type=cache,id=qtcache,target=/root/.cache/ccache \
    mkdir qt6_build && cd qt6_build && ../configure -- -D CMAKE_C_COMPILER_LAUNCHER=ccache -D CMAKE_CXX_COMPILER_LAUNCHER=ccache && cmake --build . --parallel $(nproc)

FROM ubuntu:jammy AS base-sdl
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
--mount=type=cache,target=/var/lib/apt,sharing=locked \
apt update && apt-get --no-install-recommends install -y \
build-essential git make \
pkg-config cmake ninja-build gnome-desktop-testing libasound2-dev libpulse-dev \
libaudio-dev libjack-dev libsndio-dev libx11-dev libxext-dev \
libxrandr-dev libxcursor-dev libxfixes-dev libxi-dev libxss-dev \
libxkbcommon-dev libdrm-dev libgbm-dev libgl1-mesa-dev libgles2-mesa-dev \
libegl1-mesa-dev libdbus-1-dev libibus-1.0-dev libudev-dev fcitx-libs-dev
ADD https://github.com/libsdl-org/SDL.git /sdl
RUN cmake -S /sdl -B /build &&\
  cmake --build /build -j$(nproc)

FROM ubuntu:jammy AS base-openal
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
--mount=type=cache,target=/var/lib/apt,sharing=locked \
apt update && apt-get --no-install-recommends install -y \
build-essential cmake python3-pip 
RUN apt remove -y cmake
RUN --mount=type=cache,target=/root/.cache/pip python3 -m pip install cmake 
ADD https://github.com/kcat/openal-soft.git /openal
RUN cd /openal/build && cmake .. && cmake --build . 

  # ===================================================
  # =       ===       =====     ====      ======   ====
  # =  ====  ==  ====  ===  ===  ==  ====  ===   =   ==
  # =  ====  ==  ====  ==  ========  ====  ==   ===   =
  # =  ===   ==  ====  ==  =========  ============   ==
  # =      ====       ===  ===========  ========    ===
  # =  ====  ==  ========  =============  ========   ==
  # =  ====  ==  ========  ========  ====  ==   ===   =
  # =  ====  ==  =========  ===  ==  ====  ===   =   ==
  # =  ====  ==  ==========     ====      ======   ====
  # ===================================================
  
  #RCPS3 install
  FROM build-base01 AS rpcs3
  ENV DEBIAN_FRONTEND=noninteractive 
  ENV TZ="Etc/UTC" 
  #mount and install qt
  # RUN --mount=type=bind,from=qt-base,source=/qt-everywhere-src-6.6.3,target=/qt-everywhere-src-6.6.3,rw cd qt-everywhere-src-6.6.3/qt6_build && cmake --install .
  RUN --mount=type=bind,from=qt-base,source=/qt6,target=/qt6,rw cd qt6/qt6-build && cmake --install .
  WORKDIR /
  RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
  --mount=type=cache,target=/var/lib/apt,sharing=locked \
  apt update && apt-get --no-install-recommends install -y \
  wget ca-certificates software-properties-common gpg-agent
  RUN  wget -qO- https://packages.lunarg.com/lunarg-signing-key-pub.asc | tee /etc/apt/trusted.gpg.d/lunarg.asc
  ADD https://packages.lunarg.com/vulkan/1.3.283/lunarg-vulkan-1.3.283-jammy.list /etc/apt/sources.list.d/lunarg-vulkan-1.3.283-jammy.list 
  RUN apt remove -y cmake qt6-base-private-dev libqt6svg6-dev libopenal-dev
  RUN add-apt-repository -y ppa:ubuntu-toolchain-r/test
  RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
  --mount=type=cache,target=/var/lib/apt,sharing=locked \
  apt update && apt-get --no-install-recommends install -y \
  python3-pip vulkan-sdk gcc-13 g++-13
  RUN --mount=type=cache,target=/root/.cache/pip python3 -m pip install cmake 
  ENV CXX=g++-13 
  ENV CC=gcc-13
  WORKDIR /
  RUN --mount=type=bind,from=base-sdl,source=/build,target=/build,rw \
  --mount=type=bind,from=base-sdl,source=/sdl,target=/sdl,rw \
  cmake --install /build --prefix /usr/local
  RUN --mount=type=bind,from=base-openal,source=/openal,target=/openal,rw \
  cd /openal/build && make install -j$(nproc)
  ADD --keep-git-dir https://github.com/RPCS3/rpcs3.git /rpcs3
  RUN --mount=type=cache,id=qtcache,target=/root/.cache/ccache \
  mkdir --parents rpcs3_build && cd rpcs3_build && \
  cmake -DCMAKE_PREFIX_PATH=/usr/local/Qt-6.6.3/ -DBUILD_LLVM=on -DUSE_NATIVE_INSTRUCTIONS=NO -D CMAKE_C_COMPILER_LAUNCHER=ccache -D CMAKE_CXX_COMPILER_LAUNCHER=ccache ../rpcs3/ && make -j$(nproc)

# ==================================================
# =        ===      =============       ===        =
# =  ========  ====  ============  ====  ==  =======
# =  ========  ====  ============  ====  ==  =======
# =  =========  =================  ====  ==  =======
# =      =======  =====        ==  ====  ==      ===
# =  =============  =============  ====  ==  =======
# =  ========  ====  ============  ====  ==  =======
# =  ========  ====  ============  ====  ==  =======
# =        ===      =============       ===        =
# ==================================================
  
  #ESDE 
  FROM build-base01 AS esde
  WORKDIR /
  RUN git clone https://gitlab.com/es-de/emulationstation-de.git --depth=1 esde
  RUN --mount=type=cache,id=qtcache,target=/root/.cache/ccache \
  mkdir build && cd build && cmake -DAPPLICATION_UPDATER=off -DDEINIT_ON_LAUNCH=on -D CMAKE_C_COMPILER_LAUNCHER=ccache -D CMAKE_CXX_COMPILER_LAUNCHER=ccache ../esde && make -j$(nrpoc)

  # ============================================================================
  # =  ====  ===============================    ================================
  # =  ===  =================================  =================================
  # =  ==  ==================================  =================================
  # =  =  ======   ====   ===  =  = =========  ===  =  = ====   ====   ====   ==
  # =     =====  =  ==  =  ==        ========  ===        ==  =  ==  =  ==  =  =
  # =  ==  =======  ===  ====  =  =  ========  ===  =  =  =====  ===    ==     =
  # =  ===  ====    ====  ===  =  =  ========  ===  =  =  ===    =====  ==  ====
  # =  ====  ==  =  ==  =  ==  =  =  ========  ===  =  =  ==  =  ==  =  ==  =  =
  # =  ====  ===    ===   ===  =  =  =======    ==  =  =  ===    ===   ====   ==
  # ============================================================================
                         
  # Final Image Generation
  FROM kasmweb/core-ubuntu-jammy:1.15.0 AS kasm-emulation
  USER root
  
  ENV HOME /home/kasm-default-profile
  ENV STARTUPDIR /dockerstartup
  ENV INST_SCRIPTS $STARTUPDIR/install
  WORKDIR $HOME
  
  ######### Customize Container Here ###########
 
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
--mount=type=cache,target=/var/lib/apt,sharing=locked \
apt update && apt-get --no-install-recommends install -y \
build-essential \
git \
ffmpeg \
libavcodec-dev \
libavformat-dev \
libavutil-dev \
libswscale-dev \
libevdev-dev \
libusb-1.0-0-dev \
libxrandr-dev \
libxi-dev \
libpangocairo-1.0-0 \
qt6-base-private-dev \
libqt6svg6-dev \
libbluetooth-dev \
libasound2-dev \
libpulse-dev \
libgl1-mesa-dev \
libcurl4-openssl-dev \
libopenal-dev \
libglew-dev \
zlib1g-dev \
libedit-dev \
libvulkan-dev \
libudev-dev \
libsdl2-2.0 \
libsdl2-dev \
libjack-dev \
libsndio-dev \
cmake \
libmbedtls-dev \
libpugixml-dev \
libpoppler-cpp-dev \
libfreeimage-dev \
libavfilter-dev \
libgit2-dev \
libxcb-cursor0 \
libxcb-cursor-dev \
gettext \
libharfbuzz-dev \
libicu-dev

# RUN --mount=type=cache,target=/root/.cache/pip python3 -m pip install pdftotext

  # Dolphin Emulator
  RUN --mount=type=bind,from=dolphinemu,source=/dolphin,target=/dolphin,rw \
    cd /dolphin/build && make install

  #RCPS3 
  RUN --mount=type=bind,from=qt-base,source=/qt-everywhere-src-6.6.3,target=/qt-everywhere-src-6.6.3,rw cd /qt-everywhere-src-6.6.3/qt6_build && cmake --install .
  # RUN --mount=type=bind,from=rpcs3,source=/rpcs3_build,target=/rpcs3_build \
  #   cd/ /rpcs3_build/ && make install
  COPY --from=rpcs3 /rpcs3_build/bin/ /rpcs3/
  ENV PATH=$PATH:/rpcs3
  ENV LD_LIBRARY_PATH=/usr/local/Qt-6.6.3/lib:$LD_LIBRARY_PATH
  
  ENV ES_DE_CONTAINER_VERSION 0.1-xcb
  
  #ESDE
  RUN --mount=type=bind,from=esde,source=/build,target=/build,rw \
    --mount=type=bind,from=esde,source=/esde,target=/esde,rw \
    cd /build && make install

  ######### End Customizations ###########
  
  RUN chown 1000:0 $HOME
  RUN $STARTUPDIR/set_user_permission.sh $HOME
  
  ENV HOME /home/kasm-user
  WORKDIR $HOME
  RUN mkdir -p $HOME && chown -R 1000:0 $HOME
  
  USER 1000

  # ==================================================
  # =  ====  ====  =========  ========================
  # =  ====  ====  =========  ========================
  # =  ====  ====  =========  ======  ================
  # =  ====  ====  ===   ===  =====    ===   ===    ==
  # =   ==    ==  ===  =  ==    ====  ===     ==  =  =
  # ==  ==    ==  ===     ==  =  ===  ===  =  ==  =  =
  # ==  ==    ==  ===  =====  =  ===  ===  =  ==    ==
  # ===    ==    ====  =  ==  =  ===  ===  =  ==  ====
  # ====  ====  ======   ===    ====   ===   ===  ====
  # ==================================================

FROM ghcr.io/linuxserver/baseimage-kasmvnc:ubuntujammy AS webtop-emulation 

# set version label
ARG BUILD_DATE
ARG VERSION
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="thelamer"
LABEL org.opencontainers.image.source=https://github.com/T2theV/ESDE-Docker

# title
ENV TITLE="ESDE"

# prevent Ubuntu's firefox stub from being installed
ADD https://github.com/linuxserver/docker-webtop.git#ubuntu-mate:root/etc/apt/preferences.d /etc/apt/preferences.d

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
--mount=type=cache,target=/var/lib/apt,sharing=locked \
  echo "**** add icon ****" && \
  curl -o \
    /kclient/public/icon.png \
    https://raw.githubusercontent.com/linuxserver/docker-templates/master/linuxserver.io/img/webtop-logo.png && \
  echo "**** install packages ****" && \
  add-apt-repository -y ppa:mozillateam/ppa && \
  apt-get update && \
  DEBIAN_FRONTEND=noninteractive \
  apt-get install --no-install-recommends -y \
    ayatana-indicator-application \
    firefox \
    mate-applets \
    mate-applet-brisk-menu \
    mate-terminal \
    pluma \
    ubuntu-mate-artwork \
    ubuntu-mate-default-settings \
    ubuntu-mate-desktop \
    ubuntu-mate-icon-themes && \
  echo "**** mate tweaks ****" && \
  rm -f \
    /etc/xdg/autostart/mate-power-manager.desktop \
    /etc/xdg/autostart/mate-screensaver.desktop && \
  echo "**** cleanup ****" && \
  apt-get autoclean && \
  rm -rf \
    /config/.cache \
    /config/.launchpadlib \
    /var/lib/apt/lists/* \
    /var/tmp/* \
    /tmp/*

# add local files
ADD https://github.com/linuxserver/docker-webtop.git#ubuntu-mate:root /

# ports and volumes
EXPOSE 3000
VOLUME /config


  ######### Customize Container Here ###########
 
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
--mount=type=cache,target=/var/lib/apt,sharing=locked \
apt update && apt-get --no-install-recommends install -y \
build-essential \
git \
ffmpeg \
libavcodec-dev \
libavformat-dev \
libavutil-dev \
libswscale-dev \
libevdev-dev \
libusb-1.0-0-dev \
libxrandr-dev \
libxi-dev \
libpangocairo-1.0-0 \
qt6-base-private-dev \
libqt6svg6-dev \
libbluetooth-dev \
libasound2-dev \
libpulse-dev \
libgl1-mesa-dev \
libcurl4-openssl-dev \
libopenal-dev \
libglew-dev \
zlib1g-dev \
libedit-dev \
libvulkan-dev \
libudev-dev \
libsdl2-2.0 \
libsdl2-dev \
libjack-dev \
libsndio-dev \
cmake \
libmbedtls-dev \
libpugixml-dev \
libpoppler-cpp-dev \
libfreeimage-dev \
libavfilter-dev \
libgit2-dev \
libxcb-cursor0 \
libxcb-cursor-dev \
gettext \
libharfbuzz-dev \
libicu-dev

  
  # RUN --mount=type=cache,target=/root/.cache/pip python3 -m pip install pdftotext
  
    # Dolphin Emulator
    RUN --mount=type=bind,from=dolphin-dist,source=/,target=/dolphin,rw \
      cd /dolphin/build && make install
  
    #RCPS3 
    # RUN --mount=type=bind,from=qt-base,source=/qt-everywhere-src-6.6.3,target=/qt-everywhere-src-6.6.3,rw cd /qt-everywhere-src-6.6.3/qt6_build && cmake --install .
    # RUN --mount=type=bind,from=qt-base,source=/qt6,target=/qt6,rw cd qt6/qt6-build && cmake --install .
    # RUN --mount=type=bind,from=rpcs3,source=/rpcs3_build,target=/rpcs3_build \
    #   cd/ /rpcs3_build/ && make install
    # COPY --from=rpcs3 /rpcs3_build/bin/ /rpcs3/
    # ENV PATH=$PATH:/rpcs3
    
    #ESDE
    # RUN --mount=type=bind,from=esde,source=/build,target=/build,rw \
    #   --mount=type=bind,from=esde,source=/esde,target=/esde,rw \
    #   cd /build && make install


  RUN add-apt-repository -y ppa:ubuntu-toolchain-r/test

  RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
  --mount=type=cache,target=/var/lib/apt,sharing=locked \
  apt update && apt-get --no-install-recommends install -y \
  libstdc++6
    
    ######### End Customizations ###########
    

  # ========================================================
  # ==      ========================  ======================
  # =  ====  =======================  ======================
  # =  ====  =======================  ======================
  # ==  =======  =  ==  = ====   ===  =====  ==  = ====   ==
  # ====  =====  =  ==     ==  =  ==    =======     ==  =  =
  # ======  ===  =  ==  =  ===  ====  =  ==  ==  =  ==     =
  # =  ====  ==  =  ==  =  ====  ===  =  ==  ==  =  ==  ====
  # =  ====  ==  =  ==  =  ==  =  ==  =  ==  ==  =  ==  =  =
  # ==      ====    ==  =  ===   ===  =  ==  ==  =  ===   ==
  # ========================================================
FROM lizardbyte/sunshine:latest-ubuntu-24.04 AS sunshine

ENV DEBIAN_FRONTEND=noninteractive
USER root
    RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt update && apt --no-install-recommends install -y \
    build-essential \
    git \
    ffmpeg \
    libavcodec-dev \
    libavformat-dev \
    libavutil-dev \
    libswscale-dev \
    libevdev-dev \
    libusb-1.0-0-dev \
    libxrandr-dev \
    libxi-dev \
    libpangocairo-1.0-0 \
    qt6-base-private-dev \
    libqt6svg6-dev \
    libbluetooth-dev \
    libasound2-dev \
    libpulse-dev \
    libgl1-mesa-dev \
    libcurl4-openssl-dev \
    libopenal-dev \
    libglew-dev \
    zlib1g-dev \
    libedit-dev \
    libvulkan-dev \
    libudev-dev \
    libsdl2-2.0-0 \
    libsdl2-dev \
    libjack-dev \
    libsndio-dev \
    cmake \
    libmbedtls-dev \
    libpugixml-dev \
    libpoppler-cpp-dev \
    libfreeimage-dev \
    libavfilter-dev \
    libgit2-dev \
    libxcb-cursor0 \
    libxcb-cursor-dev \
    gettext \
    libharfbuzz-dev \
    libicu-dev

  # Dolphin Emulator
  RUN --mount=type=bind,from=dolphinemu,source=/dolphin,target=/dolphin,rw \
  cd /dolphin/build && make install

  USER lizard
  ENTRYPOINT dolphin-emu && sunshine