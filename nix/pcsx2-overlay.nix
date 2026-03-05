final: prev: 
{
    pcsx2 = prev.pcsx2.overrideAttrs( old: {
        postPatch = "";
        src = prev.rpcs3.src.overrideAttrs( old: {
            tag = 0;
            rev =  (builtins.fromJSON(builtins.readFile ./pcsx2-out.json)).rev;
        });
    });
}