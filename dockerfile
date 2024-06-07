# syntax=docker/dockerfile:1



FROM ubuntu:jammy as build-base01
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
  libsndio-dev 

  #Dolphin build
  FROM build-base01 as dolphinemu
  ADD https://github.com/dolphin-emu/dolphin.git /dolphin
  WORKDIR /dolphin
  RUN mkdir build && cd build && cmake .. && make -j$(nproc)

 
  
  # ADD https://github.com/llvm/llvm-project.git#llvmorg-17.0.1 /llvm
  # WORKDIR /llvm
  # RUN cmake -S llvm -B build -G "Unix Makefiles" -D CMAKE_INSTALL_PREFIX=/usr/local -DCMAKE_BUILD_TYPE=Release && cd build && make -j $(nproc) && make install
  #Qt build and install
  from debian as qt-base
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
  libgles2-mesa-dev

  WORKDIR /
  #download and extract
  ADD https://download.qt.io/archive/qt/6.6/6.6.3/single/qt-everywhere-src-6.6.3.tar.xz /qt.tar.xz
  RUN tar xf qt.tar.xz
  #install
  WORKDIR /qt-everywhere-src-6.6.3
  RUN mkdir qt6_build && cd qt6_build && ../configure && cmake --build . --parallel $(nproc) 
  #&& cmake --install .

  #RCPS3 install
  FROM build-base01 as rpcs3
  ENV DEBIAN_FRONTEND=noninteractive 
  ENV TZ="Etc/UTC" 
  #mount and install qt
  RUN --mount=type=bind,from=qt-base,source=/qt-everywhere-src-6.6.3,target=/qt-everywhere-src-6.6.3,rw cd qt-everywhere-src-6.6.3/qt6_build && cmake --install .
  WORKDIR /
  RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
  --mount=type=cache,target=/var/lib/apt,sharing=locked \
  apt update && apt-get --no-install-recommends install -y \
  wget ca-certificates
  RUN  wget -qO- https://packages.lunarg.com/lunarg-signing-key-pub.asc | tee /etc/apt/trusted.gpg.d/lunarg.asc
  ADD https://packages.lunarg.com/vulkan/1.3.283/lunarg-vulkan-1.3.283-jammy.list /etc/apt/sources.list.d/lunarg-vulkan-1.3.283-jammy.list 
  RUN apt remove cmake qt6-base-private-dev libqt6svg6-dev -y
  RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
  --mount=type=cache,target=/var/lib/apt,sharing=locked \
  apt update && apt-get --no-install-recommends install -y \
  python3-pip vulkan-sdk gcc-11
  RUN --mount=type=cache,target=/root/.cache/pip python3 -m pip install cmake 
  ENV CXX g++-11 
  ENV CC gcc-11
  WORKDIR /
  ADD https://t2thev:$TIMSPAT@github.com/RPCS3/rpcs3.git /rpcs3
  RUN mkdir --parents rpcs3_build && cd rpcs3_build && \
  cmake -DCMAKE_PREFIX_PATH=/usr/local/Qt-6.6.3/ -DBUILD_LLVM=on ../rpcs3/ && make -j$(nproc)

  #Final Image Generation
  FROM kasmweb/core-ubuntu-jammy:1.15.0 as kasm-ubuntu
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
libsndio-dev 

  # Dolphin Emulator
  RUN --mount=type=bind,from=dolphinemu,source=/dolphin,target=/dolphin \
    cd /dolphin/build && make install

  #RCPS3 
  RUN --mount=type=bind,from=rcps3,source=/rpcs3_build,target=/rpcs3_build \
    cd /rpcs3_build/ && make install
  
  ######### End Customizations ###########
  
  RUN chown 1000:0 $HOME
  RUN $STARTUPDIR/set_user_permission.sh $HOME
  
  ENV HOME /home/kasm-user
  WORKDIR $HOME
  RUN mkdir -p $HOME && chown -R 1000:0 $HOME
  
  USER 1000
