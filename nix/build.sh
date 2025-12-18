#!/usr/bin/env nix-shell
#! nix-shell -i bash
#! nix-shell -p bash nix-prefetch-github

nix-prefetch-github --fetch-submodules --json --leave-dot-git dolphin-emu dolphin > dol.json &
nix-prefetch-github --fetch-submodules --json rpcs3 rpcs3 > rpcs3.json 

