final: prev: 
{
    pcsx2 = prev.pcsx2.overrideAttrs( old: {
        # 13.7GB build host: keep heavy compiles under the OOM line.
        NIX_BUILD_CORES = 2;
        postPatch = "";
        src = prev.pcsx2.src.overrideAttrs( old: {
            tag = 0;
            rev =  (builtins.fromJSON(builtins.readFile ./pcsx2-out.json)).rev;
            hash="";
        });
    });
}
