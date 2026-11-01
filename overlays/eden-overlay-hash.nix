final: prev:
{
    eden = prev.eden.overrideAttrs(old: {
        src = prev.eden.src.overrideAttrs(old: {
            hash=( builtins.fromJSON( builtins.readFile ./eden-full-out.json)).hash;
        });
    });
}
