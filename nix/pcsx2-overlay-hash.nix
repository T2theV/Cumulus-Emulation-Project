final: prev:
{
    pcsx2 = prev.pcsx2.overrideAttrs(old: {
        src = prev.pcsx2.src.overrideAttrs(old: {
            hash=( builtins.fromJSON( builtins.readFile ./pcsx2-full-out.json)).hash;
        });
    });
}
