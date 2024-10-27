# syntax=docker/dockerfile:latest
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
  
  RUN --mount=type=cache,target=/root/.cache/ccache/ \
<<EOT
  mkdir build
  cd build
  cmake -D CMAKE_C_COMPILER_LAUNCHER=ccache -D   CMAKE_CXX_COMPILER_LAUNCHER=ccache ..
  make -j$(nproc)
  ccache -p
  ccache -svv
EOT

  FROM scratch AS dolphin-dist
  COPY --from=dolphinemu /dolphin/build/ /build/
  COPY --from=dolphinemu /CMakeLists.txt .