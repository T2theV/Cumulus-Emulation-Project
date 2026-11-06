# hotplug-emu

udev hotplug → emulator controller-config bridge for GOW (Cumulus EP).
A single-file C++20, zero-dependency static binary + a sibling entrypoint
script (`Wiring A`: never touches GOW's `launch-comp.sh`).

## State

- **T1 PASS** — `apply` with live Dolphin.ini fixture: byte-identical output.
- **T2 PASS** — corrupt SIDevice values (6→3): `apply` restores exact fixture.
- **M3 PASS** — selftest synthetic uevent (headered): daemon receives via
  netlink group 1 multicast.
- **M4 PASS** — real uinput gamepad, full lifecycle: daemon startup scan
  catches pre-plugged pad (`SIDevice=6`), netlink `remove` clears it
  (`SIDevice=0`) at the uevent instant, daemon survives, graceful SIGTERM
  shutdown (exit 0).

## Wire format (CRITICAL — two layouts exist)

1. **Headerless (real kernel / fake-udev):** raw payload, NO `nlmsghdr`.
   `"remove@/devices/...\0ACTION=remove\0DEVNAME=input/event9\0DEVPATH=...\0SUBSYSTEM=input\0...\0"`
   (NUL-terminated KEY=VALUE tokens; DEVNAME has no `/dev` prefix.)
2. **Headered (our synthetic selftests):** `nlmsghdr` + NUL-terminated
   KEY=VALUE pairs.

The parser (`nl_recv`) detects a valid header by checking
`nlmsghdr.nlmsg_len ∈ [NLMSG_HDRLEN, received_bytes]`; otherwise it parses
the whole buffer as NUL-separated tokens. Both layouts yield the same
`Uevent{action,devname,devpath}`.

## Netlink recipe (verified working)

- Receiver: `socket(AF_NETLINK, SOCK_RAW|SOCK_CLOEXEC, NETLINK_KOBJECT_UEVENT)`
  → `bind(fd, {nl_pid=0})` → `setsockopt(NETLINK_ADD_MEMBERSHIP, grp=1)`.
  (`connect(group)` always returns EPERM.)
- Sender: same setup + `sendto(fd, msg, len, 0, {nl_pid=0, nl_groups=1}, ...)`.
  Plain `send()` leaves `nl_groups=0` → kernel unicasts to portid 0 → group
  members never see it. Requires CAP_NET_ADMIN (container runs as root).
- **Group = 1** — the ONLY multicast group on NETLINK_KOBJECT_UEVENT
  (`lib/kobject_uevent.c`: `.groups = 1`, `NL_CFG_F_NONROOT_RECV` only).
  The old "group 2" was a misreading of libudev's monitor-group enum.
- NUL separators in synthetic payloads: `push_back('\0')` — `payload += "a\0"`
  uses strlen and silently drops the NUL.

## Sysfs identity resolution (kernel ≥6.x layout)

- `<device>/capabilities/ev` — hex bitmask (EV_ABS=bit 3, EV_KEY=bit 1).
  Older kernels: `<syscls>/capabilities` decimal list (fallback kept).
- `<device>/capabilities/key` — 64-bit hex words; gamepad = EV_ABS +
  EV_KEY + a game button in bits **30–62 ∪ 299–312** (covers
  BTN_A=304..BTN_THUMBR=318 and Wolf's virtual pads mapping 48–62).
- One input device surfaces as `eventN` + `jsM` — deduped by
  `<device>/uniq`; remove matched by input-device prefix of DEVPATH.
- `capabilities` is a directory on newer kernels (not a file).

## Daemon behavior

- Startup scan catches pre-plugged pads (GOW boot catch-up).
- Netlink events processed directly; periodic sysfs rescan (~3 s) is the
  safety net (logs only on count change).
- Writes per-emulator config atomically (tmp + rename), state in
  `<rundir>/state.json`, pid file `<rundir>/pid`.
- `HPEMU_NONETLINK=1` → rescan-only mode (debug/fallback).
- Modes: `daemon`, `apply`, `status`, `probe <dev>` (diagnostics),
  `selftest-plug/unplug`, `uesim <act> <dev> <devpath>` (testing).

## Build

```
g++ -std=c++20 -O2 -Wall -static -o hotplug-emu src/hotplug-emu.cpp
# tests:
g++ -std=c++17 -O2 -static -o tests/nlmcast tests/nlmcast.c
g++ -std=c++17 -O2 -static -o tests/uinput-pad tests/uinput-pad.c   # modern uinput API
```

## Deploy (Wiring A)

`/opt/gow/prelaunch-controllers.sh` — real file beside GOW's nix-store
symlinks, the app-container entrypoint: starts the daemon (idempotent via
pid file), runs `apply --all`, then `exec /opt/gow/startup.sh`.

## Test procedure (container)

```
hpe-nltest (hello-docker:latest, --privileged, own netns, shares host /sys+/dev)
1. /uinput-pad 45 &            # creates "hotplug-emu Test Xbox Pad" (045e:02ea)
2. HPEMU_HOME=/home/hp HPEMU_RUNDIR=/run/hp /hotplug-emu daemon &
3. kill -TERM <pad pid>        # kernel emits remove uevents (event9 + js1)
4. expect: SIDevice0..3=0, state.json cleared, daemon alive
```

## Remaining

- PCSX2/RPCS3/Yuzu/PPSSPP adapters (priority after Dolphin; PCSX2 > PPSSPP).
  PCSX2 presence in the image unverified.
- Golden-file tests per adapter once emulators land in the image.
- Deploy to the real GOW container when a session is running.
