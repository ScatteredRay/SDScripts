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
          ComfyUIImage = import ./container.nix {
            name = "comfy_image";
            pkgs = import nixpkgs {
              system = "x86_64-linux";
            };
            extra_contents = [
              ComfyUI-cuda
            ];
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
