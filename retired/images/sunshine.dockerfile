# syntax=docker/dockerfile:latest
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