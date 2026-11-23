#!/usr/bin/env bash
# fetch-compat-hash.sh — pin Xenia's mutable compatibility_data.json hash.
#
# The compatibility_data.json the xenia-edge build embeds is a GitHub release
# asset behind a MUTABLE tag (xenia-canary/game-compatibility); upstream
# re-publishes it, so any hardcoded sha256 rots. This queries the GitHub
# Releases API for the asset's `digest` (sha256) and writes it to
# xenia-compat-data-hash.json, which overlays/xenia-edge-overlay.nix reads and
# feeds into the data-repos tree. Called from localbuild.sh before nix-build
# (same convention as getrev.sh / prefetch.sh).
set -euo pipefail
cd "$(dirname "$0")"

REPO="xenia-canary/game-compatibility"
TAG="game-compatibility"
ASSET="compatibility_data.json"
OUT="xenia-compat-data-hash.json"

curl_args=(-fsS)
if [ -n "${GITHUB_TOKEN:-}" ]; then
    curl_args+=(-H "Authorization: Bearer ${GITHUB_TOKEN}")
fi

DIGEST=$(curl "${curl_args[@]}" \
    "https://api.github.com/repos/${REPO}/releases/tags/${TAG}" \
    | jq -r --arg name "${ASSET}" '.assets[] | select(.name == $name) | .digest' \
    | sed 's/^sha256://')

if ! printf '%s' "${DIGEST}" | grep -Eq '^[0-9a-f]{64}$'; then
    echo "fetch-compat-hash: could not resolve a sha256 digest for ${ASSET}" >&2
    exit 1
fi

jq -n --arg url "https://github.com/${REPO}/releases/download/${TAG}/${ASSET}" \
    --arg hash "${DIGEST}" '{ url: $url, hash: $hash }' > "${OUT}"
echo "xenia-compat-data: ${DIGEST} -> ${OUT}"
