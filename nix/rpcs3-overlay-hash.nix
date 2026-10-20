final: prev:
{
    rpcs3 = prev.rpcs3.overrideAttrs(old: {
        src = prev.rpcs3.src.overrideAttrs(old: {
            hash=( builtins.fromJSON( builtins.readFile ./rpcs3-full-out.json)).hash;
        });
    });
}
