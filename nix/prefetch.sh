#!/usr/bin/env nix-shell
#! nix-shell -i bash
#! nix-shell -p bash nurl curl jq

#nix-channel --update
# nurl -e '(import <nixpkgs> { }).dolphin-emu.src.overrideAttrs(_:{tag=0; rev="9323074ada4b1d372809dc71ed092efe8d0e4c8e";})' > dolphin-emu.hash &
# nurl -e '(import <nixpkgs> { }).flycast.src.overrideAttrs(_:{tag=0; rev="ba5b3c71ecc966e52f698f41443e7cc9b81bf824";})' > flycast.hash &
# nurl -e '(import <nixpkgs> { }).pcsx2.src.overrideAttrs(_:{tag=0; rev="b7fa45ee76bb47e02ce78ebd674d3dd46d519689";})' > pcsx2.hash &
# nurl -e '(import <nixpkgs> { }).rmg.src.overrideAttrs(_:{tag=0; rev="e9167db9ffbb16e10ac62a0a449dd6bfd124493a";})' > rmg.hash &
# nurl -e '(import <nixpkgs> { }).rpcs3.src.overrideAttrs(_:{tag=0; rev="2064bd87e37da1d0946f7c5b62f2d38003abff8e";})' > rpcs3.hash &
# nurl -e '(import <nixpkgs> { }).xemu.src.overrideAttrs(_:{tag=0; rev="5aeacacfeb7a28ad7d5a9ecab9978115804148dc";})' > xemu.hash &
# nurl -e '(import <nixpkgs> { }).xenia-canary.src.overrideAttrs(_:{tag=0; rev="bc69b95db698efdcb4dcf36101b9c252d28f0c95";})' > xenia.hash &

HASH=$(nurl -e "(import <nixpkgs> { overlays= [(import ./"${1}"-overlay.nix)]; })."${1}".src")

jq --arg substitute $HASH '. += { "hash" : $substitute }' ${1}-out.json > ${1}-full-out.json
