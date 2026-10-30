# Dolphin-Emu Vulkan on the `cumulus` container (NixOS 24.05 / GOstation-wolf)

**Status: WORKING.** `dolphin-emu-nogui -v Vulkan -p x11` runs under gamescope with
hardware acceleration on the AMD Radeon RX 7800 XT (RADV NAVI32, Mesa 26.1.3).

Verified: full stack up (gamescope → Xwayland :0 → Dolphin), `card1/device/gpu_busy_percent`
~80%+, no `No DRI3 support detected` / `Failed to create Vulkan device` errors.

---

## The symptoms (what "it doesn't work" actually was)

A 4-link failure chain, each masking the next:

1. `vkCreateInstance: Found no drivers!`
2. `xwayland glamor: failed to setup GBM backend, falling back to sw accel`
3. `MESA: vulkan: No DRI3 support detected - required for presentation`
4. `Failed to create Vulkan device` → `Failed to initialize video backend!` → Dolphin exits

The chain: Vulkan-on-X11 needs DRI3 → DRI3 needs Xwayland's glamor GBM backend to
initialize → glamor GBM needs EGL/GBM to work → EGL/GBM needs Mesa's DRI driver,
which the loader couldn't find.

## Root causes (all the same disease, three symptoms)

NixOS keeps the GPU driver bits under the **nix store prefix**
(`/nix/store/gqpsfqzgbcbwbh12n3sjxk2x4gqgy8lq-mesa-26.1.3/`), which is outside
every standard loader scan path, and the container's custom entrypoint **never
creates `/run/opengl-driver`** — the runtime symlink a normal NixOS install has
that Mesa's DRI/GBM loader *hardcodes*:

```
MESA-LOADER: failed to open dri: /run/opengl-driver/lib/gbm/dri_gbm.so:
            cannot open shared object file
```

| # | Missing link | Correct target | Why it matters |
|---|--------------|----------------|----------------|
| 1 | `/home/retro/.config/vulkan/icd.d/radeon_icd.x86_64.json` | `$MESA/share/vulkan/icd.d/radeon_icd.x86_64.json` | Vulkan loader scan path — fixes "Found no drivers!" |
| 2 | `/etc/glvnd/egl_vendor.d/50_mesa.json` | `$MESA/share/glvnd/egl_vendor.d/50_mesa.json` | glvnd EGL dispatcher scan path (NOT `/etc/egl` — verified by strace; the wrong path silently does nothing) |
| 3 | `/run/opengl-driver` | `$MESA` (the nix prefix) | **THE fix.** Mesa DRI/GBM loader hardcodes `/run/opengl-driver/lib/gbm/dri_gbm.so` and `/run/opengl-driver/lib/dri/*` |

`MESA=/nix/store/gqpsfqzgbcbwbh12n3sjxk2x4gqgy8lq-mesa-26.1.3`

### Red herring: "why is there no card0?"
`card0` does exist on the host — it's the VM's **bochs-drm virtual VGA**
(`PCI_ID 1234:1111`). The RX 7800 XT enumerates after it, so it's `card1` and its
render node is `renderD128`. The container was deliberately created with only
`/dev/dri/card1` + `/dev/dri/renderD128` (Docker `HostConfig.Devices`), which is
correct — you don't want the VM's fake framebuffer in the gaming container.
A `/dev/dri/card0 → card1` symlink was tried; it's harmless but **not** the fix.

## The fix

Applied inside the container, saved to the persistent home bind mount:

**`/home/retro/fix-gpu-render.sh`** (host: `/home/tim/wolf/profile-data/user/cumulus/fix-gpu-render.sh`)

```bash
#!/bin/bash
MESA=/nix/store/gqpsfqzgbcbwbh12n3sjxk2x4gqgy8lq-mesa-26.1.3
mkdir -p /home/retro/.config/vulkan/icd.d /etc/glvnd/egl_vendor.d
ln -sf "$MESA/share/vulkan/icd.d/radeon_icd.x86_64.json" \
       /home/retro/.config/vulkan/icd.d/radeon_icd.x86_64.json
ln -sf "$MESA/share/glvnd/egl_vendor.d/50_mesa.json" \
       /etc/glvnd/egl_vendor.d/50_mesa.json
ln -sfnf "$MESA" /run/opengl-driver
```

Run as root in the container: `bash /home/retro/fix-gpu-render.sh`

Sanity check after running (must show `EGL driver name: radeonsi`):

```
gosu retro env LD_LIBRARY_PATH=$MESA/lib /sbin/eglinfo -p gbm | head
```

### Persistence caveat
- `/home/retro` is a bind mount → the script itself survives recreation.
- `/run/opengl-driver` and `/etc/glvnd/...` are on the **container layer**:
  survive `docker stop/start` (no tmpfs on /run here) but **not** container
  recreation. After any rebuild, run `fix-gpu-render.sh` once.
- If the Nix store path changes (Mesa upgrade), update `$MESA` in the script —
  find it with `ls -d /nix/store/*-mesa-*`.

## Launching Dolphin (the sanctioned GOW path)

Must run as user **`retro`** (uid 1000, owner of `/run/user/wolf`) via
**`gosu`** (the GOW user-switcher at `/sbin/gosu`), through the real GOW
launcher. Save this as `/tmp/launch.sh` (or better: a file in the persistent
home) and edit the ROM path:

```bash
#!/bin/bash
source /opt/gow/bash-lib/utils.sh
export RUN_GAMESCOPE=1
export RUN_SWAY=
export XDG_RUNTIME_DIR=/run/user/wolf
source /opt/gow/launch-comp.sh
launcher /sbin/dolphin-emu-nogui -v Vulkan -p x11 "/ROMs/gc/Super Mario Sunshine (USA).rvz"
```

Run it:

```
docker exec -it <cumulus> bash -c 'setsid /sbin/gosu retro /bin/bash /tmp/launch.sh > /tmp/gs.log 2>&1 < /dev/null &'
```

Notes:
- `dolphin-emu-nogui` only supports platforms `headless`, `fbdev`, `x11`
  — there is **no wayland platform** in this build.
- GOW's `launcher()` (from `/opt/gow/launch-comp.sh`) invokes
  `gamescope -b -W 1280 -H 720 -w 1280 -h 720 -r 60 -- <app>` — don't hand-roll
  gamescope; the wrapper handles the user context, env, and flags.
- The host-side GOstation/wolf orchestrator drives the real GUI surface; the
  manual launch above is for testing. In normal operation GOW starts the game.
- ROMs are at `/ROMs/` (host bind: `/home/tim/storage/romshare`).

## Verifying it's actually rendering (no screen in the container)

```
# 1. Full stack alive:
ps aux | grep -E "gamescope|dolphin|Xwayland" | grep -v grep   # expect 4 procs

# 2. GPU is busy (the definitive proof):
cat /sys/class/drm/card1/device/gpu_busy_percent               # ~80+

# 3. Log is clean — NONE of these may appear:
grep -iE "Found no drivers|glamor.*GBM|No DRI3|Failed to create Vulkan|Failed to initialize video" /tmp/gs.log

# 4. Positive sign: repeated
#    "ATTENTION: default value of option vk_xwayland_wait_ready overridden"
#    = Dolphin's Vulkan-on-X11 surface is active (Mesa Vulkan X11 only).

# 5. Vulkan sees the right GPU:
gosu retro /sbin/vulkaninfo --summary   # GPU0: RX 7800 XT (RADV NAVI32)
```

## Debugging trail (what didn't work / what was checked)

- `VK_ICD_FILENAMES=... vulkaninfo` — proved the ICD is good, loader-path
  problem (led to fix #1).
- `strace -e openat` on `eglinfo -p gbm` — proved the dispatcher scans
  `/run/opengl-driver/share/glvnd/egl_vendor.d`, `/etc/glvnd/egl_vendor.d`,
  `/usr/share/glvnd/egl_vendor.d` (not `/etc/egl`) — proved the Mesa vendor
  manifest was the missing piece (fix #2).
- `eglinfo -p gbm` before fix #3: manifest loaded, extensions listed, but
  `eglInitialize failed`; strace then showed `openat("/run/opengl-driver/lib/gbm/dri_gbm.so") = ENOENT`
  — proved fix #3.
- `strace` on gamescope: `/dev/dri/card1` opens `O_RDWR` fine, `libgbm`/
  `libdrm_amdgpu` load fine — ruled out device permissions as the cause.
- `DRI_PRIME=1`, `__DRM_DEVICES_AVAILABLE=card1`, `GBM_BACKEND=drm`,
  `/dev/dri/card0→card1` symlink — all harmless, none fixed it.
- `/run/udev` is an empty bind mount (host has no udev data); GBM falls back to
  probing the render node directly, which works.
- Non-fatal noise that's safe to ignore in `/tmp/gs.log`:
  `gamescope_ei`/libei failures (input injection, optional),
  `pipewire pw_context_connect failed` (screen capture, optional),
  `MESA-LOADER: failed to open drm: .../drm_gbm.so` (KMS variant — only
  `dri_gbm.so` is needed and it loads), xkbcomp fontconfig warnings.
