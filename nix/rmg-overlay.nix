final: prev:
{
    rmg = prev.rmg.overrideAttrs(old: {
        patches = [ ];
        src = prev.rmg.src.overrideAttrs(old: {
            tag=0; 
            rev=( builtins.fromJSON( builtins.readFile ./rmg-out.json)).rev;
            hash="";
        });
	buildInputs = [ old.buildInputs] ++ [ 
		prev.sdl3-net
		prev.qt6.qtbase 
	];
	nativeBuildInputs = [ old.nativeBuildInputs ] ++ [
		prev.sdl3-net
	];
    });
}
