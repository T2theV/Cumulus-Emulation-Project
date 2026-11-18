final: prev:
{
    rpcs3 = prev.rpcs3.overrideAttrs(old: {
        # 13.7GB build host: rpcs3's heavy TUs OOM at default -j32.
        NIX_BUILD_CORES = 2;
        src = prev.rpcs3.src.overrideAttrs(old: {
            tag=0; 
            rev=( builtins.fromJSON( builtins.readFile ./rpcs3-out.json)).rev;
            hash = "";
        });
    });
}
