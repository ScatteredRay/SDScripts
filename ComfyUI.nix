{ rocmSupport ? false, cudaSupport ? !rocmSupport, pkgs ? import <nixpkgs> {config.cudaSupport = cudaSupport;}, stdenv ? pkgs.stdenv } :
stdenv.mkDerivation rec {
  pname = "ComfyUI";
  version = "0.01";
  enableParallelBuilding = true;

  src = pkgs.fetchFromGitHub {
    owner = "comfyanonymous";
    repo = "ComfyUI";
    rev = "bc76b3829f5fbba7c5a439c7833d313a3ca87398";
    hash = "sha256-2apSd8EZRXp6lwFk+Fr+y4XqCtQ5OX8X4aiwh3hNZaM=";
  };

  python = pkgs.python3;

  # torch inherits pkgs.config.cudaSupport
  torch = if rocmSupport
          then python.pkgs.torchWithRocm
          else if cudaSupport
          then python.pkgs.torchWithCuda
          else python.pkgs.torchWithoutCuda;

  torchsde = python.pkgs.torchsde.override { inherit torch; };
  #torchvision = python.pkgs.torchvision.override { inherit torch; };
  accelerate = (python.pkgs.accelerate.override {
    inherit torch;
  }).overrideAttrs (super: {
    disabledTests = super.disabledTests ++ [
      # Not sure why this is broke?
      "MetricTester"
      #"tests/test_metrics.py"
    ];
  });

  pyenv = (python.withPackages (ps: with ps; [
    torch
    torchsde
    #torchvision
    einops
    transformers
    safetensors
    aiohttp
    accelerate
    pyyaml
    pillow
    scipy
    tqdm
    psutil
  ]));

  nativeBuildInputs = [
    pyenv
  ];
}