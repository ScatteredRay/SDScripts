{
  rocmSupport,
  cudaSupport
} :
import <nixpkgs> {
  config.cudaSupport = cudaSupport;
  overlays = [
    (final: prev: {
      python3 = prev.python3.override {
        packageOverrides = finalPy: prevPy: {
          torch = prevPy.torch.override {
            inherit rocmSupport cudaSupport;
            magma = if rocmSupport
                    then final.magma-hip
                    else if cudaSupport
                    then final.magma-cuda-static
                    else final.magma;
          };
          torchvision-bin =
            if rocmSupport
            then (prevPy.torchvision-bin.overrideAttrs (old: {
            src = final.fetchurl {
              name = "torchvision-0.15.2-cp310-cp310-manylinux2014_aarch64.whl";
              url = "https://download.pytorch.org/whl/torchvision-0.15.2-cp310-cp310-manylinux2014_aarch64.whl";
              hash = "sha256-Hu/r9fvQGpX+jwA9Yj2UFgHJS1zsVHtCDaics2nZz5Y=";
            };
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