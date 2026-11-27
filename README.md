# Cumulus Emulation Project

Emulators in a container, built with Nix.

This project builds a Docker image that runs **Xenia Edge** (Xbox One) behind
**Pegasus-Frontend**, rendering with Vulkan at 1080p.

## The image

Defined by `nix/gowbase.nix` (`dockerTools.buildLayeredImage`, not a NixOS
config). It ships:

- **Xenia Edge** — Xbox One emulation, from the `has207/xenia-edge` fork
  (pinned in `nix/src.nix`).
- **Pegasus-Frontend** — the launchpad frontend, auto-started on boot
  (`pegasus-fe -platform xcb`).
- **Vulkan** — the Mesa Vulkan stack (loader, headers, ICD manifests), wired
  up so emulators render via Vulkan.
- **1080p output** — the `launcher` helper defaults to 1920x1080.
- Optional display stacks: **Sway** (`RUN_SWAY=1`) and **Gamescope**
  (`RUN_GAMESCOPE=1`).

## Building

Build inside a `nixos/nix` container (a fresh store keeps the build clean):

```bash
cd nix/
./localbuild.sh                       # pin each emulator (fetch + hash)
NIXPKGS_ALLOW_UNFREE=1 nix-build gowbase.nix
```

`localbuild.sh` runs `getrev.sh` + `prefetch.sh` over `emulators-src.json` to
pin each emulator's source, then `nix-build` builds the image. The build
produces a Docker image in the Nix store; load it with `docker load -i` and
retag it.

> **Rolling hash:** Xenia's `compatibility_data.json` fetch (`nix/data-src.nix`)
> points at a mutable release asset. If the build fails on a hash mismatch,
> copy the "got" sha256 from the error into `data-src.nix` (re-pin) and
> rebuild.

## Running

```bash
docker run --rm -it \
  -v /path/to/roms:/ROMs \
  -v /path/to/config:/config \
  --device /dev/dri/renderD128 \
  <image>:latest
```

- **`/ROMs`** — your ROM/game library; BIOSes live under `/ROMs/bios`.
- **`/config`** — per-emulator config (Vulkan + 1080p are the defaults).
- **`/dev/dri/renderD128`** — the GPU render node (Vulkan).

The container boots as user `retro` (HOME `/home/retro`) and launches
`pegasus-fe`.

## How it works

The entrypoint (`nix/entrypoint.sh`) runs as root, sources
`/etc/cont-init.d/*.sh` (linuxserver-style init), fixes up the GPU renderer,
then drops to `retro` and runs `/opt/gow/startup.sh` → `startup-app.sh` → the
`launcher` helper in `nix/opt/gow/launch-comp.sh`.

Emulator versions are kept current by pinning each emulator's source in
`nix/emulators-src.json` and re-running `localbuild.sh` before each build.
