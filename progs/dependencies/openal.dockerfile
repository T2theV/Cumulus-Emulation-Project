# syntax=docker/dockerfile:latest

FROM ubuntu:jammy AS base-openal
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
--mount=type=cache,target=/var/lib/apt,sharing=locked \
apt update && apt-get --no-install-recommends install -y \
build-essential cmake python3-pip 
RUN apt remove -y cmake
RUN --mount=type=cache,target=/root/.cache/pip python3 -m pip install cmake 
ADD https://github.com/kcat/openal-soft.git /openal
RUN cd /openal/build && cmake .. && cmake --build . 

FROM scratch AS openal-dist
COPY --from=base-openal /openal /openal
