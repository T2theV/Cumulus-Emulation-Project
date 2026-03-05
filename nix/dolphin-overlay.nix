final: prev:
{
  dolphin-emu = prev.dolphin-emu.overrideAttrs (old: {
      src = prev.dolphin-emu.src.overrideAttrs(old: {
            tag=0; 
            rev=( builtins.fromJSON( builtins.readFile ./dolphin-emu-out.json)).rev;
        });
  });
}
