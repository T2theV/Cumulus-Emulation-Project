final: prev:
{
    rpcs3 = prev.rpcs3.overrideAttrs(old: {
        src = prev.rpcs3.src.overrideAttrs(old: {
            tag=0; 
            rev=( builtins.fromJSON( builtins.readFile ./rpcs3-out.json)).rev;
            hash = "";
        });
        cmakeFlags = [
             (lib.cmakeBool "STATIC_LINK_LLVM" true)
        ] ++ old.cmakeFlags;
    });
}
