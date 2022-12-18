{
  description = "Application packaged using poetry2nix";

  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs";
  inputs.poetry2nix_pkgs.url = "github:nix-community/poetry2nix";

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    poetry2nix_pkgs,
  }: (flake-utils.lib.eachDefaultSystem (system: let
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };

    poetry2nix = import poetry2nix_pkgs {
      inherit pkgs;
      poetry = pkgs.poetry;
    };

    customOverrides = self: super: {
    };

    my_env =
      poetry2nix.mkPoetryEnv
      {
        projectDir = ./.;
        preferWheels = true;
        overrides = [poetry2nix.defaultPoetryOverrides customOverrides];
        python = pkgs.python310;
      };
  in {
    devShell = pkgs.mkShell {
      buildInputs = with pkgs; [
        poetry
        my_env
      ];
    };
  }));
}
