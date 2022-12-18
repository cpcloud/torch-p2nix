{
  description = "Application packaged using poetry2nix";

  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs";
  inputs.poetry2nix = {
    url = "github:cpcloud/poetry2nix/rollup";
    inputs = {
      nixpkgs.follows = "nixpkgs";
      flake-utils.follows = "flake-utils";
    };
  };

  outputs = { self, nixpkgs, flake-utils, poetry2nix }: flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ poetry2nix.overlay ];
      };

      customOverrides = self: super: {
        nvidia-cudnn-cu11 = super.nvidia-cudnn-cu11.overridePythonAttrs (attrs: {
          nativeBuildInputs = attrs.nativeBuildInputs or [ ] ++ [ pkgs.autoPatchelfHook ];
          preFixup = ''
            addAutoPatchelfSearchPath "${self.nvidia-cublas-cu11}/${self.python.sitePackages}/nvidia/cublas/lib"
          '';
          postFixup = ''
            rm -r $out/${self.python.sitePackages}/nvidia/{__pycache__,__init__.py}
          '';
          propagatedBuildInputs = attrs.propagatedBuildInputs or [ ] ++ [
            self.nvidia-cublas-cu11
          ];
        });

        nvidia-cuda-nvrtc-cu11 = super.nvidia-cuda-nvrtc-cu11.overridePythonAttrs (_: {
          postFixup = ''
            rm -r $out/${self.python.sitePackages}/nvidia/{__pycache__,__init__.py}
          '';
        });

        torch = super.torch.overridePythonAttrs (attrs: {
          nativeBuildInputs = attrs.nativeBuildInputs or [ ] ++ [
            pkgs.autoPatchelfHook
            pkgs.cudaPackages.autoAddOpenGLRunpathHook
          ];
          buildInputs = attrs.buildInputs or [ ] ++ [
            self.nvidia-cudnn-cu11
            self.nvidia-cuda-nvrtc-cu11
            self.nvidia-cuda-runtime-cu11
          ];
          postInstall = ''
            addAutoPatchelfSearchPath "${self.nvidia-cublas-cu11}/${self.python.sitePackages}/nvidia/cublas/lib"
            addAutoPatchelfSearchPath "${self.nvidia-cudnn-cu11}/${self.python.sitePackages}/nvidia/cudnn/lib"
            addAutoPatchelfSearchPath "${self.nvidia-cuda-nvrtc-cu11}/${self.python.sitePackages}/nvidia/cuda_nvrtc/lib"
          '';
        });
      };

      env = pkgs.poetry2nix.mkPoetryEnv {
        projectDir = ./.;
        preferWheels = true;
        overrides = pkgs.poetry2nix.overrides.withDefaults customOverrides;
        python = pkgs.python310;
      };
    in
    {
      devShells.default = pkgs.mkShell {
        buildInputs = [ pkgs.poetry env ];
      };
      packages.env = env;
    }
  );
}
