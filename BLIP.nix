{ pkgs ? import <nixpkgs> {config.cudaSupport = true;}, stdenv ? pkgs.stdenv } :
stdenv.mkDerivation rec {
  pname = "BLIP";
  version = "0.01";
  enableParallelBuilding = true;

  src = pkgs.fetchFromGitHub {
    owner = "salesforce";
    repo = "BLIP";
    rev = "3a29b7410476bf5f2ba0955827390eb6ea1f4f9d";
    hash = "sha256-WX+raOYWrDdODF+AwKtDMep5+2o1Xyr4cKW02OwA9EU=";
  };

  python = pkgs.python3;

  pyenv = (python.withPackages (ps: with ps; [
    timm
    transformers
    #fairscale
    #pycocoevalcap
  ]));

  nativeBuildInputs = [
    pyenv
  ];
}