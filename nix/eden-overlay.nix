final: prev:
{
  eden = prev.eden.overrideAttrs (old: {
      src = prev.eden.src.overrideAttrs(old: {
            tag=0; 
            rev="ddac8c8eb500918bd8c89e0c330587c591206c2c";
#( builtins.fromJSON( builtins.readFile ./eden-out.json)).rev;
        });
  });
}
