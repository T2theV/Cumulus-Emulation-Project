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
  
  RUN --mount=type=cache,id=dolphincache,target=/root/.cache/ccache \
    mkdir build && cd build && cmake -D CMAKE_C_COMPILER_LAUNCHER=ccache -D CMAKE_CXX_COMPILER_LAUNCHER=ccache .. && make -j$(nproc) && ccache -svv

  FROM scratch AS dolphin-dist
  COPY --from=dolphinemu /dolphin .