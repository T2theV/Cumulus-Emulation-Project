final: prev:
{
  eden = prev.eden.overrideAttrs (old: {
#      src = prev.fetchFromGitHub {
#        owner = "eden-emulator";
#       repo = "mirror";
       src = prev.eden.src.overrideAttrs(old: {
	tag = 0;
#	 rev=( builtins.fromJSON( builtins.readFile ./eden-out.json)).rev;
	 rev= "37fe9119526c03ca064166130cc983c55b9a9e86";
         hash = "sha256-E5mIKtq4HkGFstx3laVAprYCsV8bpw4rq6cyeD0fMRw=";
        });
     buildInputs = old.buildInputs ++ [
	prev.sdl3
	prev.cpm-cmake];
     nativeBuildInputs = old.nativeBuildInputs ++ [ prev.sdl3];
     buildPhase = ''
	cpm init eden
	cpm run
  });
}
