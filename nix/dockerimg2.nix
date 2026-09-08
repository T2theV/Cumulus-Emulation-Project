{ pkgs ? import <nixpkgs> { system = "x86_64-linux"; }
}:

pkgs.dockerTools.buildLayeredImage {
  name = "hello-docker";
  tag = "latest";
  contents = [ pkgs.hello ];
  config = {
    Cmd = [ "/bin/hello" ];
  };
  
}