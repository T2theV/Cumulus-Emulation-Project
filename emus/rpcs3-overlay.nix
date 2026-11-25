final: prev:
{
    rpcs3 = prev.rpcs3.overrideAttrs(old: {
        src = prev.rpcs3.src.overrideAttrs(old: {
            tag=0; 
            rev=( builtins.fromJSON( builtins.readFile ./rpcs3-out.json)).rev;
            hash = "";
        });
        cmakeFlags = [
             "-DSTATIC_LINK_LLVM=ON"
        ] ++ old.cmakeFlags;
        patches = (old.patches or []) ++ [ ./rpcs3-llvm-jit-events.patch ];
        # llvm is only consumed at build time (its static libs are linked
        # into the binary via STATIC_LINK_LLVM); keep it out of the runtime
        # closure so the LLVM store paths (~550 MB) don't land in the image.
        buildInputs = builtins.filter (p: (p.pname or "") != "llvm") (old.buildInputs or []);
        nativeBuildInputs = (old.nativeBuildInputs or []) ++ [ prev.llvm ];
    });
}
