# syntax=docker/dockerfile:latest
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
  # RUN --mount=type=bind,from=qt-base,source=/qt6,target=/qt6,rw cd /qt6/qt6_build && cmake --install .

  
  WORKDIR /
  RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
  --mount=type=cache,target=/var/lib/apt,sharing=locked \
  apt update && apt-get --no-install-recommends install -y \
  wget ca-certificates software-properties-common gpg-agent python3-pip
  RUN  wget -qO- https://packages.lunarg.com/lunarg-signing-key-pub.asc | tee /etc/apt/trusted.gpg.d/lunarg.asc
  ADD https://packages.lunarg.com/vulkan/1.3.283/lunarg-vulkan-1.3.283-jammy.list /etc/apt/sources.list.d/lunarg-vulkan-1.3.283-jammy.list 
  RUN apt remove -y cmake qt6-base-private-dev libqt6svg6-dev libopenal-dev
  RUN add-apt-repository -y ppa:ubuntu-toolchain-r/test
  RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
  --mount=type=cache,target=/var/lib/apt,sharing=locked \
  apt update && apt-get --no-install-recommends install -y \
  python3-pip vulkan-sdk gcc-13 g++-13 
  RUN bash -c "$(wget -O - https://apt.llvm.org/llvm.sh)"
  RUN --mount=type=cache,target=/root/.cache/pip python3 -m pip install cmake aqtinstall
  run aqt install-qt linux desktop 6.8.2 -O /usr/local/Qt -m qtmultimedia 
  ENV CXX=g++-13 
  ENV CC=gcc-13
  WORKDIR /
  RUN --mount=type=bind,from=base-sdl,source=/build,target=/build,rw \
  --mount=type=bind,from=base-sdl,source=/sdl,target=/sdl,rw \
  cmake --install /build --prefix /usr/local
  RUN --mount=type=bind,from=base-openal,source=/openal,target=/openal,rw \
  cd /openal/build && make install -j$(nproc)
  ADD --keep-git-dir https://github.com/RPCS3/rpcs3.git /rpcs3
  RUN --mount=type=cache,target=/root/.cache/ccache \
  mkdir --parents rpcs3_build && cd rpcs3_build && \
  cmake -DCMAKE_PREFIX_PATH=/usr/local/Qt/6.8.2/gcc_64/   -DCMAKE_C_COMPILER_LAUNCHER=ccache -DCMAKE_CXX_COMPILER_LAUNCHER=ccache ../rpcs3/ && make -j$(nproc) \
  && ccache -s && sleep 11
