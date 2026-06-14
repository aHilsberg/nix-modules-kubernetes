{
    description = "Opinionated kubernetes tooling flake-parts module";

    inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
        flake-parts.url = "github:hercules-ci/flake-parts";
        import-tree.url = "github:vic/import-tree";

        devshell = {
            url = "github:USE-MY-ENERGY-GmbH/nix-modules-devshell";
            # url = "path:./submodules/nix-modules-devshell";
            inputs.nixpkgs.follows = "nixpkgs";
            inputs.flake-parts.follows = "flake-parts";
            inputs.import-tree.follows = "import-tree";
        };
    };

    outputs = {...} @ inputs:
        inputs.flake-parts.lib.mkFlake {inherit inputs;} (
            {
                inputs,
                config,
                lib,
                withSystem,
                flake-parts-lib,
                ...
            }: let
                projectLib = import ./lib.nix {inherit (inputs.nixpkgs) lib;};
                inherit (flake-parts-lib) importApply;
                kubernetesFlakeModule = importApply ./flake-module.nix {
                    inherit projectLib withSystem;
                };
            in {
                imports = [
                    inputs.devshell.flakeModule
                    inputs.flake-parts.flakeModules.modules # to use flake-parts module system; see https://flake.parts/options/flake-parts-modules.html
                    ./pkgs.nix
                    (inputs.import-tree
                      .filterNot (
                        path:
                            lib.hasSuffix ".no-auto-import.nix" path
                    )
                    ./test)
                ];

                flake.overlays = {
                    devshell = inputs.devshell.overlays.default;
                };

                systems = [
                    "x86_64-linux"
                    "aarch64-linux"
                    "aarch64-darwin"
                ];

                flake.flakeModule = config.flake.flakeModules.default;
                flake.flakeModules.default = kubernetesFlakeModule;

                perSystem = {pkgs, ...}: {
                    formatting.enable = true;
                    git-hooks.enable = true;
                    gitignore = {
                        enable = true;
                        entries = [
                        ];
                    };

                    # options reference: https://github.com/numtide/devshell/blob/main/docs/src/modules_schema.md
                    # all other options are from nix-modules-devshell
                    devshells.default = {
                        nix.enable = true;
                        json.enable = true;
                        yaml.enable = true;
                        markdown.enable = true;

                        packages = with pkgs; [
                            nushell
                        ];
                    };
                };
            }
        );
}
