final: prev:
{
    dolphin-emu = prev.dolphin-emu.overrideAttrs(old: {
        src = prev.dolphin-emu.src.overrideAttrs(old: {
            hash=( builtins.fromJSON( builtins.readFile ./dolphin-emu-full-out.json)).hash;
        });
    });
}
