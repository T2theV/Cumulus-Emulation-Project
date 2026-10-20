final: prev:
{
  zbicSrc = prev.fetchFromGitHub {
      owner = "kinnay";
      repo = "zbic";
      rev = "11b08f2712264bbed731545085cbd9702096ceb7";
      sha256 = "sha256-pHvxa1gkUvQo6mUgmLWtj1kcu01BLdGmttZyb8ZAj/o=";
  };
  eden = prev.eden.overrideAttrs (old: {
    
    src = prev.eden.src.overrideAttrs(old: {
	    tag = 0;
	    rev = (builtins.fromJSON( builtins.readFile ./eden-out.json)).rev;
#	    rev = "37fe9119526c03ca064166130cc983c55b9a9e86";
      hash = "sha256-w+GrA3jnO8vdom+t2KgIQXMT/iJOZNFLYXtM3kXt7CI=";
    });
    cmakeFlags = [
      "-DZBIC_INCLUDE_DIR=${final.zbicSrc}/src"
    ] ++ old.cmakeFlags;
    buildInputs = old.buildInputs ++ [
      final.zbicSrc
      prev.sdl3
      prev.cpm-cmake
    ];
    nativeBuildInputs = old.nativeBuildInputs ++ [ 
        final.zbicSrc
        prev.sdl3
    ];
    patches = [./eden-cmake.patch];
  });
}
