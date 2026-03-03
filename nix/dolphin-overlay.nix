final: prev:
{
  dolphin-emu = prev.dolphin-emu.overrideAttrs (old: {
    src = prev.dolphin-emu.src.overrideAttrs(old: {
        tag = 0;  
        rev = "d58e7ca9325217574d84d961b824e0acbf2f67e9";
        hash = "";
    });
  });
}
