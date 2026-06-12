final: prev:
{
  eden = prev.eden.overrideAttrs (old: {
      src = prev.eden.src.overrideAttrs(old: {
            tag=0; 
            rev="ad9af2502712ad41ae29ed078b332ff1a6875ae8";
#( builtins.fromJSON( builtins.readFile ./eden-out.json)).rev;
        });
  });
}
