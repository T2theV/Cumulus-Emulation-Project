# Override Mesa to drop every LLVM-based software driver -> removes llvm from the image.
# Kept (real AMD GPU, no LLVM):
#   gallium: radeonsi (RX 7800 XT), softpipe (C software fallback), virgl (gamescope/virt)
#   vulkan:  amd (RADV)
# Dropped (all LLVM-based):
#   gallium llvmpipe, gallium zink (lavapipe), vulkan swrast (lavapipe), d3d12/Dozen
#   + all non-AMD vendor drivers (Intel, Nouveau, ARM/Apple, WSL, etc.)
#
# NOTE: Mesa's output list (out/opencl/spirv2dxil/cross_tools) is FIXED (not overridable)
# and its postInstall is the moveToOutput block. Overriding postInstall replaces that block,
# so we (a) copy the Rusticl OpenCL ICD (meson installs it under $out/lib) into $opencl/lib
# because the postFixup patchelf step expects it there, and (b) ensure the fixed outputs
# exist (spirv2dxil is only produced by the dropped Dozen/d3d12 driver -> left empty).
final: prev: {
  mesa = (prev.mesa.override {
    galliumDrivers = [ "radeonsi" "softpipe" "virgl" ];
    vulkanDrivers = [ "amd" ];
  }).overrideAttrs {
    postInstall = ''
      if [ -e "$out/lib/libRusticlOpenCL.so" ]; then
        mkdir -p $opencl/lib
        cp -a "$out/lib/libRusticlOpenCL.so"* $opencl/lib/
      fi
      mkdir -p $spirv2dxil $opencl $cross_tools
    '';
  };
}
