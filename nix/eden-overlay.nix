final: prev:
{
  eden = prev.eden.overrideAttrs (old: {
      src = prev.eden.src.overrideAttrs(old: {
            tag=0; 
            rev="772e38cb8d9d1076305e7f02a4434c2ab54ae249";
#( builtins.fromJSON( builtins.readFile ./eden-out.json)).rev;
        });
  });
}
