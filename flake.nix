{
  description = "Flake for Stable Diffusion and image models.";

  inputs = {
    nixpkgs.url = "nixpkgs";
  };

  outputs = { self, nixpkgs } :
    let
      ComfyUI = {rocmSupport, cudaSupport} :
        import ./ComfyUI.nix {
          inherit nixpkgs rocmSupport cudaSupport;
          allowUnfree = true;
          allowBroken = true;
          system = "x86_64-linux";
        };
    in {
      packages = {
        x86_64-linux = rec {
          ComfyUI-cuda = ComfyUI {
            rocmSupport = false;
            cudaSupport = true;
          };
          ComfyUI-rocm = ComfyUI {
            rocmSupport = true;
            cudaSupport = false;
          };
          ComfyUIImage = import ./container.nix rec {
            name = "comfy_image";
            pkgs = import nixpkgs {
              system = "x86_64-linux";
              config.allowUnfree = true;
            };
            extra_contents = [
              #pkgs.cudaPackages.cudatoolkit
              #pkgs.libnvidia-container
              #pkgs.nvidia-docker # I think we actually want libnvidia-container
              #pkgs.cudaPackages.nvidia_driver
              #pkgs.nvidia-persistenced
              #pkgs.nvidia-settings
              #pkgs.nvidia-x11
              #pkgs.linuxPackages.nvidia_x11
              ComfyUI-cuda
            ];
            extra_supervisor_config = ComfyUI-cuda.supervisorConfig;
          };
          Image = import ./container.nix {
            pkgs = import nixpkgs {
              system = "x86_64-linux";
            };
          };
        };
      };
    };
}
