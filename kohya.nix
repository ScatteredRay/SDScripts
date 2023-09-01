{ rocmSupport ? false, cudaSupport ? !rocmSupport, pkgs ? import ../nixpkgs { config.cudaSupport = cudaSupport;  }, stdenv ? pkgs.stdenv,  } :
stdenv.mkDerivation rec {
  pname = "kohya_ss";
  version = "0.01";
  enableParallelBuilding = true;

  python = pkgs.python3;

  # torch inherits pkgs.config.cudaSupport
  torch = if rocmSupport
          then python.pkgs.torchWithRocm
          else if cudaSupport
          then python.pkgs.torchWithCuda
          else python.pkgs.torchWithoutCuda;

  xformers = python.pkgs.xformers.override { inherit torch; };
  bitsandbytes = python.pkgs.bitsandbytes.override { inherit torch; };

  pyenv = (python.withPackages (ps: with ps; [
    torch
    #torchvision
    xformers
    bitsandbytes
    tensorboard
    tensorflow-bin
    tkinter
    #gradio
  ]));

  nativeBuildInputs = [
    pkgs.libstdcxx5
    pyenv
  ];
  #TK_LIBRARY = "${pkgs.tk}/lib/${pkgs.tk.libPrefix}";
  LD_LIBRARY_PATH = pkgs.lib.strings.concatStringsSep ":" ["${pkgs.stdenv.cc.cc.lib}/lib" "${pkgs.zlib}/lib"];
}