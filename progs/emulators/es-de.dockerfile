# syntax=docker/dockerfile:latest
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

  FROM scratch AS esde-dist
  COPY --from=esde /build .

  FROM scratch as esde-dist
  COPY --from=esde /build /build
  COPY --from=esde /esde /esde 