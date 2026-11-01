# Nix source definitions for the four runtime data files that
# xenia-build.py's fetch_data_repos() downloads, pinned for reproducibility.
#
# Mirrors build/data_repos/:
#   game-patches/                    (whole repo, community game patches)
#   x360db/games.json                (game database)
#   SDL_GameControllerDB/gamecontrollerdb.txt   (controller database)
#   game-compatibility/{compatibility_data.json, master.json}
#
# Pinned to the refs the script would track today (branch heads), not the
# mutable branch refs: fetchFromGitHub pins by commit; the single-file
# fetchurls point at raw.githubusercontent.com/<owner>/<repo>/<commit>/<path>,
# which is immutable. compatibility_data.json comes from the rolling
# release tag — mutable, see item 4.
let p = import <nixpkgs> {};
    xenia-src = (import ./src.nix).src;  # grafted xenia-edge src (master.json)
in rec {
  # 1. Community game patches — CMake reads <this>/patches at build time
  #    (src/xenia/patcher/CMakeLists.txt).
  game-patches = p.fetchFromGitHub {
    owner = "xenia-canary";
    repo = "game-patches";
    rev = "fe957a050e37f5a1e3f485ca43c2e37ee2a9c92d";  # main
    sha256 = "DuhZftcjDCF1uAJzq1iSdGWVT8WFhi+zYYfwqUqRtzQ=";
  };

  # 2. Game database — the x360db repo is ~667 MB, so fetch just games.json
  #    at the pinned commit (the script sparse-checks out only this file).
  games-json = p.fetchurl {
    url = "https://raw.githubusercontent.com/xenia-manager/x360db/43b5de9ba4f0d64eb5181d362efef2f0c58b7f11/games.json";  # main
    sha256 = "ELpK1lHkc0GY+Pd8ALadiVCQKQbrsn4yieuAKZy3C40=";
  };

  # 3. Controller database — same: only gamecontrollerdb.txt is needed.
  gamecontrollerdb = p.fetchurl {
    url = "https://raw.githubusercontent.com/mdqinc/SDL_GameControllerDB/22a98f6339abf4b6ca6cb061443a70e4f7ab252d/gamecontrollerdb.txt";  # master
    sha256 = "DxeDG2qeDp/C9Sv4qxvvHTD/0wfZZsIRjlVts0XqfpY=";
  };

  # 4. Game compatibility data — release asset. The tag is MUTABLE: the
  #    repo's CI re-publishes the asset (the data lives in the repo's issues;
  #    the repo itself has no data file), so re-pin the hash when upstream
  #    updates — the build error prints the new hash.
  compatibility-data = p.fetchurl {
    url = "https://github.com/xenia-canary/game-compatibility/releases/download/game-compatibility/compatibility_data.json";
    sha256 = "fe3e435e40f94eb7093e71c873a7725dcfb5d5147500a652f058f0db705a95c7";
  };

  # Combined tree mirroring build/data_repos/, plus the vendored
  # master.json taken from the pinned xenia-edge src (assets/... is in the
  # FOD tarball).
  data-repos = p.runCommand "xenia-data-repos" {} ''
    mkdir -p $out/game-patches $out/x360db $out/SDL_GameControllerDB $out/game-compatibility
    cp -r ${game-patches}/* $out/game-patches/
    cp ${games-json} $out/x360db/games.json
    cp ${gamecontrollerdb} $out/SDL_GameControllerDB/gamecontrollerdb.txt
    cp ${compatibility-data} $out/game-compatibility/compatibility_data.json
    cp ${xenia-src}/assets/game-compatibility/master.json $out/game-compatibility/master.json
  '';
}
