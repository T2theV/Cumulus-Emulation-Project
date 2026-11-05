# hotplug-emu — STATUS / RESUME DOC
Last updated: 2026-11-05 (UTC). Paused by user — resume from "Next steps".

## What this is
Small C++20 zero-dep program `hotplug-emu` for GOW (games-on-whales) app containers
(cumulusEP etc.): listens for the udev hotplug signal (NETLINK_KOBJECT_UEVENT on the
GROUP_UDEV netlink group — the same channel fake-udev broadcasts on) and writes
controller-emulation config files per emulator based on the plugged-in controller.

## Decisions (user-approved, 2026-11-05)
- **Wiring A**: real file `/opt/gow/prelaunch-controllers.sh` beside the nix-store symlinks,
  = app-container entrypoint. It applies config for all emulators, then
  `exec /opt/gow/startup.sh` (→ startup-app.sh → launcher <app>). **launch-comp.sh is NOT
  modified** (GOW-managed, symlink into /nix/store).
- **Adapter priority**: Dolphin → PCSX2 → RPCS3 → Yuzu → PPSSPP (user: "ps2 is more than
  ppsspp"; PCSX2 added to the emulator set — verify it's actually in the image; if not,
  small separate image-build task).
- **Design**: single binary, C++20, zero-dep raw netlink (like fake-udev itself — no python3,
  no grep/which in containers). Two modes: `daemon` (listener + live rewrites) and one-shot
  CLI `apply --emu <name>` (called from the prelaunch script). Atomic writes (tmp+rename),
  boot-time sysfs rescan (netlink is not replayed — late start must discover pad from
  /sys/class/input), state.json, remove → revert to defaults.
- M4 adapters (PCSX2/RPCS3/Yuzu/PPSSPP) are best-effort templates; only Dolphin is verifiable
  (only Dolphin exists in the live container).
- **Milestones**: M1 reader spike ✅ → M2 daemon skeleton → M3 Dolphin adapter + prelaunch
  script (gate: verified in scratch container) → M4 other adapters → M5 Nix packaging into
  CEM image (repo /opt/data/Cumulus-Emulation-Project).

## Verified facts (2026-11-05)
- Container: `cumulusEP_0030bda9-2e7c-4d9d-b7c8-d6a267239aca` (image `hello-docker:latest`),
  GPU /dev/dri/card1 + renderD128, user retro, caps include SYS_ADMIN/MKNOD/NET_ADMIN.
- **1 controller**: "Wolf X-Box One (virtual) pad", USB ID 045e:02ea,
  /dev/input/event9 (13:73) + /dev/input/js1 (13:1), sysfs
  `/devices/virtual/input/input88/event9`. fake-udev-creatable (NO host /dev/input
  passthrough — only GPU is passed).
- fake-udev: container `/usr/bin/fake-udev` bind-mounted from host `/home/tim/wolf/fake-udev`.
  `/run/udev` bind-mounted from host (`/home/tim/wolf/profile-data/user/cumulusEP/udev`);
  `/run/udev/control` exists (fake-udev component #1); `/run/udev/data/` empty now
  (device currently unplugged; entries appear/disappear with plug/unplug).
- **Signal readable in-container (proven)**: `udevadm monitor --subsystem=input` running, then:
  `echo -ne "ACTION=add\0DEVNAME=input/event9\0DEVPATH=/devices/virtual/input/input88/event9\0SEQNUM=9999\0SUBSYSTEM=input\0" | base64 | /usr/bin/fake-udev`
  → monitor printed `UDEV  [912398.269856] add      /devices/virtual/input/input88/event9 (input)`.
  (GOW doc page: games-on-whales.github.io/wolf/stable/dev/fake-udev.html — "Hotplug in Docker".)
- **Dolphin 2609a** (nightly): `/nix/store/aj4a97d232jpfc5cisj9zh2c6gp71xbr-dolphin-emu-2609a`,
  `/sbin/dolphin-emu`. Config `~/.config/dolphin-emu/Dolphin.ini`; `[Core]` has
  `SIDevice0..3` (all = 6 currently); **no GameConfig/ dir** (Dolphin-Qt layout, no per-game
  controller INIs on disk). Container log shows it consuming hotplug:
  `[i] Gamepad: Connected/Disconnected device 0x0 (Microsoft Xbox One)`.
- Container tooling: `/sbin/udevadm` present; NO python3/grep/which/tar/unzip (minimal NixOS);
  `find`/`mktemp`/`head`/`tail`/`wc` OK. /tmp absent in club images.
- `/opt/gow/`: all entries are symlinks into /nix/store except the dir + `bash-lib/`.
  Launch chain: entrypoint → `startup.sh` → `exec startup-app.sh` → (sources launch-comp.sh)
  → `launcher <app>` → gamescope/sway/`exec $@`.
- Repo: `/opt/data/Cumulus-Emulation-Project`, branch `canned-init-update`
  (untracked docs/graph files pre-existing — fine).
- **Build flow** (skill devops-cumulus-nix-builds): `agent-nix` container (nixos/nix, running)
  holds tree at `/root/cumulus` — sync host edits with `docker cp`; build:
  `docker exec agent-nix bash -c 'cd /root/cumulus/nix && NIXPKGS_ALLOW_UNFREE=1 nix-build gowbase.nix'`
  → output is the docker image itself (dockerTools.buildLayeredImage); tag it, `docker load`,
  probe: `docker run --rm --entrypoint sh <img> -c '...'`. Long builds: detached
  `docker exec -d` + status file + poll.
- **Docker daemon ≠ this shell's host**: CLI talks to the wolf host (`/home/tim/...` mounts
  don't exist on this box). `docker cp` into /tmp of club images fails (no /tmp); transfer via
  `docker exec -i <c> bash -c 'cat > /path' < file` (stdin crosses the host boundary).
- Host (this box): Debian, g++ 14.2 / cmake 3.31 / make 4.4 in /usr/bin, home /opt/data.

## Next steps (resume here)
1. **Decode Dolphin config format (was mid-this when paused)**:
   - `SIDeviceN` in `[Core]` = SI device **type** enum (SerialInterface::SIDevices) — find the
     enum in dolphin-emu source (master ≈ 2609a) and decode what **6** is; determine correct
     value for an Xbox One / XInput pad (and what "none" is).
   - Find where the **new ControllerConfig** (SDL joystick id → controller profile) is stored
     (which INI section/file) — Dolphin.ini has no such section yet, meaning the new UI was
     never exercised; the adapter must write whatever Dolphin 25.x+ actually reads at
     controller init (check `ControllerManager`/`ControllerConfig` in source).
   - This decides the exact bytes the Dolphin adapter writes. Candidate shape:
     (a) `[Core] SIDeviceN = <type>`, (b) controller-profile section binding ports → the
     hot-plugged SDL device (index computed from /dev/input/js* enumeration order — pad is
     the only js in GOW containers, so index is 0 in practice).
2. **Scratch container for tests** (do NOT disturb the live session): create from same image
   (`docker create` + `--entrypoint /bin/sleep` + start), `docker cp` / stdin-transfer the
   hotplug-emu binary in, run daemon, fire fake-udev events, inspect Dolphin.ini.
3. **Project dir** (create here): src/hotplug-emu.cpp (single file, C++20), nix/ derivation,
   scripts/prelaunch-controllers.sh (wiring A text already drafted in chat), tests/ (golden
   files + the captured uevent fixture below).
4. **Build**: host `g++ -std=c++20 -O2 -static` for container testing (fake-udev precedent:
   2.6MB static, no deps); Nix derivation for M5.
5. **M3 gate**: in scratch container — fake-udev add event → Dolphin.ini `[Core] SIDevice*`
   updated atomically with all other sections preserved; remove event → revert; prelaunch
   script end-to-end (apply → exec startup.sh).
6. **M4**: PCSX2 → RPCS3 → Yuzu → PPSSPP adapters (best-effort templates; verify only when
   those emus land in the image).
7. **M5**: wire into CEM repo (pattern per skill: runCommand content + `/etc/cont-init.d`
   boot trigger, gosu retro), build via agent-nix, tag image, verify, push when user asks.

## Test fixtures captured
- Real uevent seen by udevadm monitor (2026-11-05):
  `UDEV  [912398.269856] add      /devices/virtual/input/input88/event9 (input)`
- fake-udev payload that reproduces it (see "Verified facts" above).
- Xbox One ID: vendor 045e product 02ea; name "Wolf X-Box One (virtual) pad".
