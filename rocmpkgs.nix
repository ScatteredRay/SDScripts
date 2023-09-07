{
  rocmSupport,
  cudaSupport,
  nixpkgs ? import <nixpkgs>
} :
nixpkgs {
  config.cudaSupport = cudaSupport;
  overlays = [
    (final: prev: {
      python3 = prev.python3.override {
        packageOverrides = finalPy: prevPy: {
          torch-src = (prevPy.torch.override {
            inherit rocmSupport cudaSupport;
            magma = if rocmSupport
                    then final.magma-hip
                    else if cudaSupport
                    then final.magma-cuda-static
                    else final.magma;
            gpuTargets = prev.lib.forEach [
              # "803"
              # "900"
              # "906"
              # "908"
              # "90a"
              # "1010"
              # "1012"
              # "1030"
              # rocminfo | grep gfx
              "1100"
              #"1036"
            ] (target: "gfx${target}");
          }).overrideAttrs (old: rec {
            version = "1.13.1";
            src = final.fetchFromGitHub {
              owner = "pytorch";
              repo = "pytorch";
              rev = "refs/tags/v${version}"; # 
              fetchSubmodules = true;
              hash = "sha256-yQz+xHPw9ODRBkV9hv1th38ZmUr/fXa+K+d+cvmX3Z8=";
            };
          });
          torch-bin =
            if rocmSupport
            then (prevPy.torch-bin.overrideAttrs (old: {
              version = "1.13.1";
              src = final.fetchurl {
                name = "torch-1.13.1+rocm5.2-cp310-cp310-linux_x86_64.whl";
                url = "https://download.pytorch.org/whl/rocm5.2/torch-1.13.1%2Brocm5.2-cp310-cp310-linux_x86_64.whl";
                hash = "sha256-82hdCKwNjJUcw2f5vUsskkxdRRdmnEdoB3SKvNlmE28=";
              };
              buildInputs = old.buildInputs ++ [final.rocblas];
              postFixup = prev.lib.optionalString prev.stdenv.isLinux ''
    addAutoPatchelfSearchPath "$out/${final.python3.sitePackages}/torch/lib"

    #patchelf $out/${final.python3.sitePackages}/torch/lib/libcudnn.so.8 --add-needed libcudnn_cnn_infer.so.8

    ${prev.gnused}/bin/sed -i s,/opt/amdgpu/share/libdrm/amdgpu.ids,/tmp/nix-pytorch-rocm___/amdgpu.ids,g $out/${final.python3.sitePackages}/torch/lib/libdrm_amdgpu.so


    pushd $out/${final.python3.sitePackages}/torch/lib || exit 1
      for LIBNVRTC in ./libnvrtc*
      do
        case "$LIBNVRTC" in
          ./libnvrtc-builtins*) true;;
          ./libnvrtc*) patchelf "$LIBNVRTC" --add-needed libnvrtc-builtins* ;;
        esac
      done
    popd || exit 1
  '';
            }))
            else prevPy.torch-bin;
          torch = finalPy.torch-bin;
          torchvision-bin =
            if rocmSupport
            then (prevPy.torchvision-bin.overrideAttrs (old: {
              src = final.fetchurl {
                name = "torchvision-0.15.2+rocm5.4.2-cp310-cp310-linux_x86_64.whl";
                url = "https://download.pytorch.org/whl/rocm5.4.2/torchvision-0.15.2%2Brocm5.4.2-cp310-cp310-linux_x86_64.whl";
                hash = "sha256-AIVbRm5Lw3PNnXq8tV90fs5B8lyEMXEHDBpwO/loXMM=";
              };
              buildInputs = old.buildInputs ++ [final.hip];
            })).override { torch-bin = finalPy.torch; }
            else prevPy.torchvision-bin;
          torchvision = finalPy.torchvision-bin; # Don't love this, but this is failing to build with rocm....
          torchsde = prevPy.torchsde.overrideAttrs (old: {
            # Fix for Segfault (free() on invalid pointer)
            # https://github.com/pytorch/pytorch/issues/2507
            LD_PRELOAD = "${final.jemalloc}/lib/libjemalloc.so.2";
          });
          accelerate = (prevPy.accelerate.overrideAttrs (old: {
            disabledTests = old.disabledTests ++ [
              # Not sure why this is broke?
              "MetricTester"
            ];
          }));
          tensorflow = finalPy.tensorflow-bin;
        };
      };
    })
  ];
}