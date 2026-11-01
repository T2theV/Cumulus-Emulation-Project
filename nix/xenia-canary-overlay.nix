final: prev: {
    xenia-canary = prev.xenia-canary.overrideAttrs(old: {
        src = prev.xenia-canary.src.overrideAttrs( old: {
            tag = 0;
            rev=( builtins.fromJSON( builtins.readFile ./xenia-canary-out.json)).rev;
            hash = "";
        });
    });
}
