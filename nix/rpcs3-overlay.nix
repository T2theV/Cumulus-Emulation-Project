final: prev:
{
    rpcs3 = prev.rpcs3.overrideAttrs(old: {
        buildInputs = [ prev.protobuf ] ++ old.buildInputs;
        cmakeFlags = [ (prev.lib.cmakeBool "USE_SYSTEM_PROTOBUF" true) ] ++ old.cmakeFlags;
        src = prev.rpcs3.src.overrideAttrs(old: {
            tag=0; 
            rev=( builtins.fromJSON( builtins.readFile ./rpcs3-out.json)).rev;
        });
    });
}
