# syntax=docker/dockerfile:latest

FROM ubuntu:noble AS base-openal
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
--mount=type=cache,target=/var/lib/apt,sharing=locked \
apt update && apt-get --no-install-recommends install -y \
build-essential cmake python3-pip 
# RUN apt remove -y cmake
# RUN --mount=type=cache,target=/root/.cache/pip python3 -m pip install --break-system-packages cmake 
ADD https://github.com/kcat/openal-soft.git /openal
RUN cd /openal/build && cmake .. && cmake --build . 
