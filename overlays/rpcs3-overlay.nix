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
        # llvm only consumed at build time (statically linked); keep it
        # out of the runtime closure so LLVM store paths don't land in image.
        buildInputs = builtins.filter (p: (p.pname or "") != "llvm") (old.buildInputs or []);
        nativeBuildInputs = (old.nativeBuildInputs or []) ++ [ prev.llvm ];
    });
}
