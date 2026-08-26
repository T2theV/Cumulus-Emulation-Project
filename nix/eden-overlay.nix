final: prev:
{
  eden = prev.eden.overrideAttrs (old: {
      src = prev.fetchFromGitHub {
        owner = "eden-emulator";
        repo = "mirror";
        rev=( builtins.fromJSON( builtins.readFile ./eden-out.json)).rev;
        };
  });
}
