final: prev:
{
    xenia-canary = prev.xenia-canary.overrideAttrs(old: {
        src = prev.xenia-canary.src.overrideAttrs(old: {
            hash=( builtins.fromJSON( builtins.readFile ./xenia-canary-full-out.json)).hash;
        });
    });
}
