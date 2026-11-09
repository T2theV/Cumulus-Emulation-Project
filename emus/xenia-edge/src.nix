# Nix source (FOD) definition for has207/xenia-edge @ edge branch.
#
# The superproject is fetched WITHOUT submodules (fetchSubmodules = false);
# the 34 submodules the x86_64 Linux build actually consumes (in-tree
# #include, shader, or CMake references) are fetched as
# their own FODs — each pinned at the exact gitlink commit recorded in the
# superproject — and grafted into the tree at their third_party/ paths.
# A superproject re-pin then re-fetches only the superproject; the
# submodules stay in the store as their own entries.
#
# Dropped (the 8 submodules with NO in-tree references at all): MoltenVK,
# SPIRV-Cross, SDL3, cereal, cpplint, asio, zstd, and mesa (its only
# reference is a CMake block guarded by `if(WIN32 OR APPLE)`).
# NOTE: every other dropped-looking submodule (snappy, xxhash, zarchive,
# pugixml, miniaudio, cxxopts, discord-rpc, libusb, DirectXShaderCompiler,
# metal-cpp, xbyak_aarch64, FidelityFX-*) is STILL fetched: their
# libraries are system-converted in the CMake diff, but sources/shaders
# still #include their in-tree headers, so the trees must stay.
#
# Re-pinning a submodule pointer: update its rev + sha256 (a nix fetch
# error prints the new hash); detect moved pointers with
# `git ls-tree -r <rev> | awk '$1=="160000"'`.
let p = import <nixpkgs> {};
in rec {
    superproject = p.fetchFromGitHub {
      owner = "has207";
      repo = "xenia-edge";
      rev = "f466500c3bec97ac0a070f183ecc27d30ef40579";
      fetchSubmodules = false;
      sha256 = "me5hhYhYOUJkcbxh9+Vvdxd5gcx1Br0ODQ5suBcTE8M=";
    };
    FFmpeg = p.fetchFromGitHub {
      owner = "has207";
      repo = "FFmpeg";
      rev = "c4f44071adecd5e568470e58ab4bdf483598dbc8";
      sha256 = "88wlx16mrFw9U0OWoNdRwnWN9wdHdlcGAaOmVSTs4LI=";
    };
    wxWidgets = p.fetchFromGitHub {
      owner = "wxWidgets";
      repo = "wxWidgets";
      rev = "670835aec7e54b9e9d5a50d6a1aea1e8ba0bcdb2";
      # 12 nested submodules (3rdparty/pcre, src/zlib, src/png, src/expat, src/tiff,
      # src/jpeg, ...) — CMake checks 3rdparty/pcre; fetch recursively
      fetchSubmodules = true;
      sha256 = "KAfWJFFKcI6vuIcMpaizOuFhzo7QW+n4akI8GYdB9N8=";
      postFetch = ''
        # The fetcher strips only the top-level .git; submodule checkouts
        # can leave .git entries behind (carrying run-specific temp
        # paths) — remove every .git so the source nar is clean and
        # reproducible.
        find $out -depth -name .git -exec rm -rf {} +
      '';
    };
    zlib-ng = p.fetchFromGitHub {
      owner = "zlib-ng";
      repo = "zlib-ng";
      rev = "860e4cff7917d93f54f5d7f0bc1d0e8b1a3cb988";
      sha256 = "Khmrhp5qy4vvoQe4WgoogpjWrgcUB/q8zZeqIydthYg=";
    };
    glslang = p.fetchFromGitHub {
      owner = "KhronosGroup";
      repo = "glslang";
      rev = "a57276bf558f5cf94d3a9854ebdf5a2236849a5a";
      sha256 = "/DwdyuSGCx22zsXZrcZGTECfsIqvzPQzTZ2mU8EkjxY=";
    };
    SPIRV-Tools = p.fetchFromGitHub {
      owner = "KhronosGroup";
      repo = "SPIRV-Tools";
      rev = "7f2d9ee926f98fc77a3ed1e1e0f113b8c9c49458";
      sha256 = "NXxC5XLvEEIAlA0sym6l7vWj+g8pJ4trsJI3pmZwRxU=";
    };
    SPIRV-Headers = p.fetchFromGitHub {
      owner = "KhronosGroup";
      repo = "SPIRV-Headers";
      rev = "01e0577914a75a2569c846778c2f93aa8e6feddd";
      sha256 = "gewCQvcVRw+qdWPWRlYUMTt/aXrZ7Lea058WyqL5c08=";
    };
    capstone = p.fetchFromGitHub {
      owner = "capstone-engine";
      repo = "capstone";
      rev = "66b08439abd988e87b4542389b4937ce13bd0063";
      sha256 = "ZWSHDy2oDt2yvUlNRK8kB0CQ/3qbhwrEYWWClRWkG6k=";
    };
    boost-context = p.fetchFromGitHub {
      owner = "boostorg";
      repo = "context";
      rev = "d2142b69252150dafb5f6569b7eb9a42312a92a3";
      sha256 = "zENtwWL5veHWwZ+QYvYQhDd3vrHo8B2ncta230fjjxQ=";
    };
    mbedtls = p.fetchFromGitHub {
      owner = "Mbed-TLS";
      repo = "mbedtls";
      rev = "068ff080b369adfac81509f9b57b2afabaf82dc5";
      # nested framework repo (CI/test) — fetch recursively
      fetchSubmodules = true;
      sha256 = "t1ZPeFA3ftKaEIaXQ7RXZEsiOAYK4KSSm55SFr9g17A=";
      postFetch = ''
        # The fetcher strips only the top-level .git; submodule checkouts
        # can leave .git entries behind (carrying run-specific temp
        # paths) — remove every .git so the source nar is clean and
        # reproducible.
        find $out -depth -name .git -exec rm -rf {} +
      '';
    };
    Vulkan-Headers = p.fetchFromGitHub {
      owner = "KhronosGroup";
      repo = "Vulkan-Headers";
      rev = "8864cdc896bbc2a9b6eb36b3218fc9ef57908d77";
      sha256 = "RcUVurC+Rc0MyWpQLaLVmdn7FZO1GWWzTZZAOwvKwb4=";
    };
    VulkanMemoryAllocator = p.fetchFromGitHub {
      owner = "GPUOpen-LibrariesAndSDKs";
      repo = "VulkanMemoryAllocator";
      rev = "1d8f600fd424278486eade7ed3e877c99f0846b1";
      sha256 = "TPEqV8uHbnyphLG0A+b2tgLDQ6K7a2dOuDHlaFPzTeE=";
    };
    DirectX-Headers = p.fetchFromGitHub {
      owner = "microsoft";
      repo = "DirectX-Headers";
      rev = "33374754f65baac0500dda6187e371136357246f";
      sha256 = "yMpmqMoMYtL0tlHbgxAUwgZHV3uQ3gk3wF0Xm8QW+tA=";
    };
    disruptorplus = p.fetchFromGitHub {
      owner = "xenia-canary";
      repo = "disruptorplus";
      rev = "bf9c70c0cc92b6435f7edec75e12751ea37e5c2f";
      sha256 = "F9HSipw4SygiSe3/jUEft4dNyiT1HuX4P8ggF6zehPE=";
    };
    xbyak = p.fetchFromGitHub {
      owner = "herumi";
      repo = "xbyak";
      rev = "9d8ff37306f39c6a71cf998078cbe880ce5dc224";
      sha256 = "vHm/xN3n2Xc2zPw2l3q4BXDqPluP9VlndlJIOmLBYGU=";
    };
    fmt = p.fetchFromGitHub {
      owner = "fmtlib";
      repo = "fmt";
      rev = "407c905e45ad75fc29bf0f9bb7c5c2fd3475976f";
      sha256 = "ZmI1Dv0ZabPlxa02OpERI47jp7zFfjpeWCy1WyuPYZ0=";
    };
    tomlplusplus = p.fetchFromGitHub {
      owner = "marzer";
      repo = "tomlplusplus";
      rev = "708fff700f36ab3c2ab107b984ec9f3b8be5f055";
      sha256 = "YvX5gP9OAMYwwcKj66GF+SEKFBGQXnq0uJQbEq/8WtY=";
    };
    imgui = p.fetchFromGitHub {
      owner = "ocornut";
      repo = "imgui";
      rev = "4806a1924ff6181180bf5e4b8b79ab4394118875";
      sha256 = "mQOJ6jCN+7VopgZ61yzaCnt4R1QLrW7+47xxMhFRHLQ=";
    };
    catch = p.fetchFromGitHub {
      owner = "catchorg";
      repo = "Catch2";
      rev = "ee1450f268dfd5c13aa8670ba97e93cabaf2e15d";
      sha256 = "3XNhcoblTnBPc8p2vdG5Gz+/rvFd3ffPwxMcpZPaz/0=";
    };
    date = p.fetchFromGitHub {
      owner = "HowardHinnant";
      repo = "date";
      rev = "f94b8f36c6180be0021876c4a397a054fe50c6f2";
      sha256 = "n6HDy26XGI0AkNWG0aSH8iILVaG4EkH3B6hFCGE1XMM=";
    };
    utfcpp = p.fetchFromGitHub {
      owner = "nemtrif";
      repo = "utfcpp";
      rev = "65701fe00700577f9f4e9b96d682bd7cfcc0b76e";
      # nested extern/ftest test dep — fetch recursively
      fetchSubmodules = true;
      sha256 = "13nSVTuglsxt+x8py+tVC/1L9nGzHPHZYlIE3atY03Y=";
      postFetch = ''
        # The fetcher strips only the top-level .git; submodule checkouts
        # can leave .git entries behind (carrying run-specific temp
        # paths) — remove every .git so the source nar is clean and
        # reproducible.
        find $out -depth -name .git -exec rm -rf {} +
      '';
    };
    rapidjson = p.fetchFromGitHub {
      owner = "Tencent";
      repo = "rapidjson";
      rev = "7c73dd7de7c4f14379b781418c6e947ad464c818";
      # nested thirdparty/gtest test dep — fetch recursively
      fetchSubmodules = true;
      sha256 = "lRg5rPQAnpbGz9JM3PNGGUPVSupST3da87Cdi4tj55A=";
      postFetch = ''
        # The fetcher strips only the top-level .git; submodule checkouts
        # can leave .git entries behind (carrying run-specific temp
        # paths) — remove every .git so the source nar is clean and
        # reproducible.
        find $out -depth -name .git -exec rm -rf {} +
      '';
    };
    metal-cpp = p.fetchFromGitHub {
      owner = "bkaradzic";
      repo = "metal-cpp";
      rev = "9a8bc57c0318b84863bec2faf6605594877c5f5d";
      sha256 = "/OiNdCJ/dwa3+gDIHHJoMJvFQMBpss9gFW9bZedSK5M=";
    };
    libusb = p.fetchFromGitHub {
      owner = "libusb";
      repo = "libusb";
      rev = "a61afe5f75d969c4561a1d0ad753aa23cee6329a";
      sha256 = "ntfDh/+HYm5cthhO8FkAJHo4RcxvZUKmHf4AOrHLysM=";
    };
    xbyak_aarch64 = p.fetchFromGitHub {
      owner = "fujitsu";
      repo = "xbyak_aarch64";
      rev = "59c6a7e7368cd2dbb07c46abe83239ace4d58849";
      sha256 = "WHmVeTW+eZUBpmd1g7LNRqOH9kx+NkvERAtv+weIpv4=";
    };
    FidelityFX-CAS = p.fetchFromGitHub {
      owner = "GPUOpen-Effects";
      repo = "FidelityFX-CAS";
      rev = "9fabcc9a2c45f958aff55ddfda337e74ef894b7f";
      # Nested submodules (tests/samples/externals) recorded as
      # gitlinks — fetch recursively like the original single-FOD fetch.
      fetchSubmodules = true;
      sha256 = "5m6cwNEJnXABgDZ4WsuXYFmmqT/g0sBuFBQHN+akdbQ=";
      postFetch = ''
        # The fetcher strips only the top-level .git; submodule checkouts
        # can leave .git entries behind (carrying run-specific temp
        # paths) — remove every .git so the source nar is clean and
        # reproducible.
        find $out -depth -name .git -exec rm -rf {} +
      '';
    };
    FidelityFX-FSR = p.fetchFromGitHub {
      owner = "GPUOpen-Effects";
      repo = "FidelityFX-FSR";
      rev = "a21ffb8f6c13233ba336352bdff293894c706575";
      # Nested submodules (tests/samples/externals) recorded as
      # gitlinks — fetch recursively like the original single-FOD fetch.
      fetchSubmodules = true;
      sha256 = "DBoAM3geW/km/FzYiouO1oVGgfyOwNiQdMONTX1tYeQ=";
      postFetch = ''
        # The fetcher strips only the top-level .git; submodule checkouts
        # can leave .git entries behind (carrying run-specific temp
        # paths) — remove every .git so the source nar is clean and
        # reproducible.
        find $out -depth -name .git -exec rm -rf {} +
      '';
    };
    DirectXShaderCompiler = p.fetchFromGitHub {
      owner = "microsoft";
      repo = "DirectXShaderCompiler";
      rev = "69e54e29086b7035acffb304cec57a350225f8b0";
      # Nested submodules (tests/samples/externals) recorded as
      # gitlinks — fetch recursively like the original single-FOD fetch.
      fetchSubmodules = true;
      sha256 = "pfdAD+kRpmqW29Y8jn6+X5Ujy/9cIvisYr0tH1PuxsY=";
      postFetch = ''
        # The fetcher strips only the top-level .git; submodule checkouts
        # can leave .git entries behind (carrying run-specific temp
        # paths) — remove every .git so the source nar is clean and
        # reproducible.
        find $out -depth -name .git -exec rm -rf {} +
      '';
    };
    snappy = p.fetchFromGitHub {
      owner = "google";
      repo = "snappy";
      rev = "6af9287fbdb913f0794d0148c6aa43b58e63c8e3";
      # Nested submodules (tests/samples/externals) recorded as
      # gitlinks — fetch recursively like the original single-FOD fetch.
      fetchSubmodules = true;
      sha256 = "wnqwsIkFqHrxOptrxZ67Z27hKXdafsN9pgz+QzaYvbg=";
      postFetch = ''
        # The fetcher strips only the top-level .git; submodule checkouts
        # can leave .git entries behind (carrying run-specific temp
        # paths) — remove every .git so the source nar is clean and
        # reproducible.
        find $out -depth -name .git -exec rm -rf {} +
      '';
    };
    xxhash = p.fetchFromGitHub {
      owner = "Cyan4973";
      repo = "xxHash";
      rev = "e626a72bc2321cd320e953a0ccf1584cad60f363";
      sha256 = "h6kohM+NxvQ89R9NEXZcYBG2wPOuB4mcyPfofKrx9wQ=";
    };
    zarchive = p.fetchFromGitHub {
      owner = "exzap";
      repo = "ZArchive";
      rev = "b467f7aa342895e66a1a003377ed63b3c1be3de3";
      sha256 = "zNextcdpbqRIDLyh5AFPL6F67QpdBgyT/8ygFnxRur4=";
    };
    pugixml = p.fetchFromGitHub {
      owner = "zeux";
      repo = "pugixml";
      rev = "b2b466403084667c90a0f0cc4e960405cfc8117a";
      sha256 = "4iM6YY6b1Ra6SkRfksawXULQX/v9w7gnQ8ocHFKkAKg=";
    };
    miniaudio = p.fetchFromGitHub {
      owner = "mackron";
      repo = "miniaudio";
      rev = "9634bedb5b5a2ca38c1ee7108a9358a4e233f14d";
      sha256 = "2k346Z/ueINPbaY20P2cbBvRfFXXH0ugdv4d7WaYt2w=";
    };
    cxxopts = p.fetchFromGitHub {
      owner = "jarro2783";
      repo = "cxxopts";
      rev = "f029892dab60526184ee42ae63a7f6d19a6b0e49";
      sha256 = "WLan9t87lziUrSe+GR8u/q7+GIPtWSvlg8eaG5JNbhs=";
    };
    discord-rpc = p.fetchFromGitHub {
      owner = "discordapp";
      repo = "discord-rpc";
      rev = "963aa9f3e5ce81a4682c6ca3d136cddda614db33";
      sha256 = "vz2djopNQNbCIT+HwrIc0UVVXn/UPa0rZSaO6/knhDA=";
    };
  src = p.runCommand "xenia-edge-f466500c3-src" {} ''
  mkdir -p $out
  cp -a ${superproject}/. $out/
  chmod -R u+w $out
  # The superproject carries every gitlink path as an uninitialized
  # (empty) directory; empty dirs don't exist in git, so delete them all,
  # then graft the 21 submodules the build uses.
  find $out/third_party -depth -type d -empty -exec rmdir {} +
  cp -a ${FFmpeg} $out/third_party/FFmpeg
  cp -a ${wxWidgets} $out/third_party/wxWidgets
  cp -a ${zlib-ng} $out/third_party/zlib-ng
  cp -a ${glslang} $out/third_party/glslang
  cp -a ${SPIRV-Tools} $out/third_party/SPIRV-Tools
  cp -a ${SPIRV-Headers} $out/third_party/SPIRV-Headers
  cp -a ${capstone} $out/third_party/capstone
  cp -a ${boost-context} $out/third_party/boost_context/context
  cp -a ${mbedtls} $out/third_party/mbedtls
  cp -a ${Vulkan-Headers} $out/third_party/Vulkan-Headers
  cp -a ${VulkanMemoryAllocator} $out/third_party/VulkanMemoryAllocator
  cp -a ${DirectX-Headers} $out/third_party/DirectX-Headers
  cp -a ${disruptorplus} $out/third_party/disruptorplus
  cp -a ${xbyak} $out/third_party/xbyak
  cp -a ${fmt} $out/third_party/fmt
  cp -a ${tomlplusplus} $out/third_party/tomlplusplus
  cp -a ${imgui} $out/third_party/imgui
  cp -a ${catch} $out/third_party/catch
  cp -a ${date} $out/third_party/date
  cp -a ${utfcpp} $out/third_party/utfcpp
  cp -a ${rapidjson} $out/third_party/rapidjson
  cp -a ${metal-cpp} $out/third_party/metal-cpp
  cp -a ${libusb} $out/third_party/libusb
  cp -a ${xbyak_aarch64} $out/third_party/xbyak_aarch64
  cp -a ${FidelityFX-CAS} $out/third_party/FidelityFX-CAS
  cp -a ${FidelityFX-FSR} $out/third_party/FidelityFX-FSR
  cp -a ${DirectXShaderCompiler} $out/third_party/DirectXShaderCompiler
  cp -a ${snappy} $out/third_party/snappy
  cp -a ${xxhash} $out/third_party/xxhash
  cp -a ${zarchive} $out/third_party/zarchive
  cp -a ${pugixml} $out/third_party/pugixml
  cp -a ${miniaudio} $out/third_party/miniaudio
  cp -a ${cxxopts} $out/third_party/cxxopts
  cp -a ${discord-rpc} $out/third_party/discord-rpc
''
;
}
