
{
    tag=0; 
    rev="928856567670d123b88b458f450bae0051deecb7";
    postCheckout = ''
          cd $out/3rdparty
          git submodule update --init \
            fusion/fusion asmjit/asmjit yaml-cpp/yaml-cpp SoundTouch/soundtouch stblib/stb \
            feralinteractive/feralinteractive protobuf
        '';
}
    