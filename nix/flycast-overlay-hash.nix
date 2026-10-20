final: prev:
{
    flycast = prev.flycast.overrideAttrs(old: {
        src = prev.flycast.src.overrideAttrs(old: {
            hash=( builtins.fromJSON( builtins.readFile ./flycast-full-out.json)).hash;
        });
    });
}
