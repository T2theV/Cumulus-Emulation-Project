#!/usr/bin/env nix-shell
#! nix-shell -i bash
#! nix-shell -p bash nix-prefetch-github

# nix-prefetch-github --fetch-submodules --json --no-deep-clone cemu-project cemu > cemu.json &
nix-prefetch-github --fetch-submodules --json --no-deep-clone dolphin-emu dolphin > dol.json &
nix-prefetch-github --fetch-submodules --json --no-deep-clone flyinghead flycast > flycast.json &
nix-prefetch-github --fetch-submodules --json --no-deep-clone PCSX2 pcsx2 > pcsx2.json &
nix-prefetch-github --fetch-submodules --json --no-deep-clone rosalie241 rmg > rmg.json &
nix-prefetch-github --fetch-submodules --json --no-deep-clone rpcs3 rpcs3 > rpcs3.json &
nix-prefetch-github --fetch-submodules --json --no-deep-clone xemu-project xemu > xemu.json &
nix-prefetch-github --fetch-submodules --json --no-deep-clone xenia-canary xenia-canary > xenia.json &
wait

nix-store --gc

