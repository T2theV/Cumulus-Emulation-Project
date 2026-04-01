{ pkgs ? import <nixpkgs> { }
, pkgsLinux ? import <nixpkgs> { system = "x86_64-linux"; }
}:

pkgs.dockerTools.buildImage {
  name = "hello-docker";
  config = {
    Cmd = [ "/bin/hello" ];
  };
  
  copyToRoot = pkgs.buildEnv {
    name = "image-root";
    paths = [ pkgsLinux.hello ];
    pathsToLink = [ "/bin" ];
  };
}