{
  rocmSupport ? false,
  cudaSupport ? !rocmSupport,
  nixpkgs ? import <nixpkgs>,
  pkgs ? import ./rocmpkgs.nix { inherit nixpkgs rocmSupport cudaSupport; },
  stdenv ? pkgs.stdenv
} :
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

  pyenv = (python.withPackages (ps: with ps; [
    torch
    torchsde
    torchvision
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

  shellHook = ''
  if [ ! -e /tmp/nix-pytorch-rocm___/amdgpu.ids ]
  then
    mkdir -p /tmp/nix-pytorch-rocm___
    ln -s ${pkgs.libdrm}/share/libdrm/amdgpu.ids /tmp/nix-pytorch-rocm___/amdgpu.ids
  fi
  '';
}