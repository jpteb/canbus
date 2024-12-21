{
  description = "A flake for the REMAP CanBus Experiment";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    treefmt.url = "github:numtide/treefmt-nix";
    pre-commit-hooks-nix.url = "github:cachix/pre-commit-hooks.nix";
  };

  outputs =
    inputs@{ flake-parts, nixpkgs, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.treefmt.flakeModule
        inputs.pre-commit-hooks-nix.flakeModule
      ];

      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];

      perSystem =
        {
          config,
          self',
          inputs',
          pkgs,
          system,
          ...
        }:
        {
          _module.args.pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
          # Per-system attributes can be defined here. The self' and inputs'
          # module parameters provide easy access to attributes of the same
          # system.
          treefmt = {
            projectRootFile = ".gitignore";
            settings.global.excludes = [
              "Libraries/**"
              "Core/**"
            ];
            programs.nixfmt.enable = true;
            programs.clang-format.enable = true;
          };
          formatter = config.treefmt.build.wrapper;

          devShells.default = pkgs.mkShell {
            packages = with pkgs; [
              cmake
              clang-tools
              doxygen
              gcc-arm-embedded
              glibc_multi # for the 32-bit headers of gcc
              meson
              ninja
              protobuf
              pyocd
              python312
              python312Packages.protobuf
              python312Packages.pyocd
              stlink
              stm32cubemx # Our own version and not from pkgs
            ];
          };
        };
    };
}
