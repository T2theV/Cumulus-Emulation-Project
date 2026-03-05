final: prev:
{
    rmg = prev.rmg.overrideAttrs(old: {
        patches = [ ];
        src = prev.rmg.src.overrideAttrs(old: {
            tag=0; 
            rev=( builtins.fromJSON( builtins.readFile ./rmg-out.json)).rev;
        });
    });
}