{ pkgs ? import <nixpkgs> {config.cudaSupport = true;}, stdenv ? pkgs.stdenv } :
stdenv.mkDerivation rec {
  pname = "SDScripts";
  version = "0.01";
  enableParallelBuilding = true;

  python = pkgs.python3;

  pyenv = (python.withPackages (ps: with ps; [
  ]));

  nativeBuildInputs = [
    pyenv
    pkgs.exiftool
  ];
}