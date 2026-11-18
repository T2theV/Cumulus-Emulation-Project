final: prev:
{
  # Sources for eden's CPM-resolved deps, fetched at build-planning time
  # (hermetic, no in-build network) and handed to CPM via <NAME>_CUSTOM_DIR
  # so CPMUtil skips its download entirely.
  #
  # fetchgit (not GitHub tarballs): codeload tarballs are
  # regenerated non-deterministically when caches are rebuilt, so byte-pinning
  # them is unstable (verified: same URL, different bytes across fetches).
  # Git commits are content-addressed and stable forever.
  zbicSrc = prev.fetchgit {
      url = "https://github.com/kinnay/zbic.git";
      rev = "11b08f2712264bbed731545085cbd9702096ceb7";
      sha256 = "a47bf16b582452f428ea652098b5ad8f591cbb4d412dd1a6b6d6726fc6408ffa";
  };
  jacinthSrc = prev.fetchgit {
      url = "https://github.com/crueter/jacinth.git";
      rev = "bb91f708c171bdfc76060944c64a816717bde47f";
      sha256 = "f0a9645940a0de339809a92ffb5bd5a0a376ac1dcc538b72bc46a50759d05c6a";
  };
  hydrocarbonSrc = prev.fetchgit {
      url = "https://github.com/crueter/hydrocarbon.git";
      rev = "f4ec2a3754f35e61f271f869955d2cbd4b2778fe";
      sha256 = "cdac96d5691e673fa18b9dc149c7daaa9b2922bdee323e6d3e6c654a89c59362";
  };
  eden = prev.eden.overrideAttrs (old: {
    # The video_core TUs (renderer_vulkan.cpp et al) compile with
    # -flto=auto -fmodules-ts and peak well over 6GB each; the build host
    # has 13.7GB total. 32-way parallel compiles trip the OOM killer.
    # stdenv reads NIX_BUILD_CORES from the build environment; a per-derivation
    # attribute is the only reliable override (sandbox env comes from the nix
    # daemon, not the caller).
    NIX_BUILD_CORES = 2;
    src = prev.eden.src.overrideAttrs(old: {
	    tag = 0;
	    rev = (builtins.fromJSON( builtins.readFile ./eden-out.json)).rev;
      hash = "sha256-w+GrA3jnO8vdom+t2KgIQXMT/iJOZNFLYXtM3kXt7CI=";
    });
    cmakeFlags = [
      "-DZBIC_INCLUDE_DIR=${final.zbicSrc}/src"
      "-DENABLE_RESHADE=OFF"
    ] ++ old.cmakeFlags ++ [
      "-DCPMUTIL_FORCE_SYSTEM:BOOL=OFF"
      "-Djacinth_CUSTOM_DIR=${final.jacinthSrc}"
      "-Dhydrocarbon_CUSTOM_DIR=${final.hydrocarbonSrc}"
    ];
    buildInputs = old.buildInputs ++ [
      final.zbicSrc
      final.jacinthSrc
      final.hydrocarbonSrc
      prev.sdl3
      prev.cpm-cmake
    ];
    nativeBuildInputs = old.nativeBuildInputs ++ [
        final.zbicSrc
        prev.sdl3
        prev.curl
    ];
    patches = [./eden-cmake.patch];
    postConfigure="";
    postInstall="";
  });
}
