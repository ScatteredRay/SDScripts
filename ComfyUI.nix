{
  rocmSupport ? false,
  cudaSupport ? !rocmSupport,
  system ? "x86_64-linux",
  allowUnfree ? true,
  allowBroken ? false,
  nixpkgs ? <nixpkgs>,
  pkgs ? import ./rocmpkgs.nix {
    inherit nixpkgs system allowUnfree allowBroken rocmSupport cudaSupport;
  },
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

  # Store path??
  supervisorConfig = ''
  [program:comfyui]
  command=${pyenv}/bin/python3 /ComfyUI/main.py --listen 0.0.0.0 --port 8188
  '';

  nativeBuildInputs = [
    pyenv
  ];

  shellHook = if rocmSupport then ''
  if [ ! -e /tmp/nix-pytorch-rocm___/amdgpu.ids ]
  then
    mkdir -p /tmp/nix-pytorch-rocm___
    ln -s ${pkgs.libdrm}/share/libdrm/amdgpu.ids /tmp/nix-pytorch-rocm___/amdgpu.ids
  fi
  '' else "";

  installPhase = ''
    mkdir -p $out/ComfyUI
    mkdir -p $out/bin
    cp -r $src/* $out/ComfyUI
  '';
}