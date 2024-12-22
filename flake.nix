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
        let
                  devPythonEnv = pkgs.python312.withPackages(ps: [
                ps.aioconsole
                ps.cffi
                ps.cmsis-pack-manager
                ps.protobuf
                ps.pyocd
                ps.pyserial
          ]);
        in
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
              devPythonEnv
              doxygen
              gcc-arm-embedded-13
              glibc_multi # for the 32-bit headers of gcc
              meson
              minicom
              ninja
              protobuf
              pyocd
              stlink
              stm32cubemx # Our own version and not from pkgs
            ];
          };
        };
    };
}
