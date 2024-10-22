{
  rocmSupport ? false,
  cudaSupport ? !rocmSupport,
  nixpkgs ? import <nixpkgs>,
  pkgs ? import ./rocmpkgs.nix { inherit nixpkgs rocmSupport cudaSupport; },
  stdenv ? pkgs.stdenv
} :
stdenv.mkDerivation rec {
  pname = "kohya_ss";
  version = "0.01";
  enableParallelBuilding = true;

  python = pkgs.python3;

  pyenv = (python.withPackages (ps: with ps; [
    torch
    torchvision
    xformers
    bitsandbytes
    tensorboard
    tensorflow
    tkinter
    #gradio
    wandb
  ]));

  nativeBuildInputs = [
    pkgs.libstdcxx5
    pyenv
  ];
  #TK_LIBRARY = "${pkgs.tk}/lib/${pkgs.tk.libPrefix}";
  LD_LIBRARY_PATH = pkgs.lib.strings.concatStringsSep ":" ["${pkgs.stdenv.cc.cc.lib}/lib" "${pkgs.zlib}/lib"];
}