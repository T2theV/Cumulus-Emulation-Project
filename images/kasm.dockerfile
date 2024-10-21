# syntax=docker/dockerfile:latest
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
