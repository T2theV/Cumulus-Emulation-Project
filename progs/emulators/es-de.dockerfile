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
  RUN mkdir build && cd build && cmake -DDEINIT_ON_LAUNCH=on -DAPPLICATION_UPDATER=off ../esde && make -j$(nrpoc)

  # FROM scratch AS esde-dist
  # COPY --from=esde /build .
