final: prev:
{
  dolphin-emu = prev.dolphin-emu.overrideAttrs (old: {
      # 13.7GB build host: keep heavy compiles under the OOM line.
      NIX_BUILD_CORES = 2;
      src = prev.dolphin-emu.src.overrideAttrs(old: {
            tag=0; 
            rev=( builtins.fromJSON( builtins.readFile ./dolphin-emu-out.json)).rev;
            hash="";
        });
  });
}
