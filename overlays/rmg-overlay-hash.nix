final: prev:
{
    rmg = prev.rmg.overrideAttrs(old: {
        src = prev.rmg.src.overrideAttrs(old: {
            hash=( builtins.fromJSON( builtins.readFile ./rmg-full-out.json)).hash;
        });
    });
}
