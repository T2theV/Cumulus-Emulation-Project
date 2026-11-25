# Mesa-LLVM slim overlay — v2.1
#
# nixpkgs mesa builds the VA state tracker, which links libgallium against
# libLLVM.so (unconditional, ~952 C++ symbols). Mesa receives LLVM through
# the `llvmPackages` argument:
#   - preConfigure: PATH=$(lib.getDev llvmPackages.libllvm)/bin  -> llvm-config
#   - buildInputs:  llvmPackages.libllvm (multi-output derivation: all outputs)
#
# The multi-output llvm derivation's `-lib` output carries 208 static .a
# archives (~360 MB) plus libLLVM.so (~190 MB). Nothing at runtime needs the
# archives. This overlay redefines mesa with a slimmed llvmPackages where
# libllvm is a single-output derivation containing:
#   lib/     = -lib output minus *.a
#   bin/     = -dev output bin (llvm-config)
#   include/ = -dev output headers
#
# llvm-config bakes its absolute --prefix/--libdir store paths into the
# binary, so they are repointed byte-for-byte at the slim output. Mesa's
# meson then links the slim libLLVM.so, and its store path (and only that)
# is baked into libgallium's RUNPATH -> the exportReferencesGraph closure
# contains the slim output, not the full -lib output.
#
# mesa = mesa-slim = prev.mesa.override { llvmPackages = <slim>; }

{ final, prev }:
let
  libllvm = prev.mesa.llvmPackages.libllvm;   # multi-output derivation

  slim-lib = final.runCommand "${libllvm.name}-lib-slim" {
    nativeBuildInputs = [ final.python3 ];
  } ''
    mkdir -p $out/lib $out/bin $out/include
    cp -a ${libllvm.lib}/lib/. $out/lib
    cp -a ${libllvm.dev}/bin/. $out/bin
    cp -a ${libllvm.dev}/include/. $out/include
    chmod -R u+w $out
    python3 - <<PY
import glob, os
out = "$out"
# Drop the static archives (~360 MB) — nothing at runtime needs them:
for f in glob.glob(out + "/lib/**/*.a", recursive=True):
    os.remove(f)
# Repoint llvm-config's baked-in store paths at this slim output:
p = out + "/bin/llvm-config"
data = open(p, "rb").read()
for old in (b"${libllvm.lib}", b"${libllvm.dev}"):
    assert data.count(old) >= 1, "path not found in llvm-config: " + old.decode()
    data = data.replace(old, out.encode())
open(p, "wb").write(data)
PY
    # Smoke-test: llvm-config must now report the slim libdir
    test "$( $out/bin/llvm-config --libdir )" = "$out/lib"
    test "$( $out/bin/llvm-config --version )" = "${libllvm.version}"
  '';

  llvm-slim = prev.mesa.llvmPackages // { inherit slim-lib; };

  mesa-slim = prev.mesa.override { llvmPackages = llvm-slim; };
in
{
  mesa = mesa-slim;
}
