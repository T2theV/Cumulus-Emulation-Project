final: prev:
{
    flycast = prev.flycast.overrideAttrs(old: {
      buildInputs = old.buildInputs ++ [prev.systemd];
      cmakeFlags = old.cmakeFlags ++ [ "-DUSE_OPENGL=OFF" ];
        src = prev.flycast.src.overrideAttrs(old: {
            tag=0; 
            rev=( builtins.fromJSON( builtins.readFile ./flycast-out.json)).rev;
        });
    });
}