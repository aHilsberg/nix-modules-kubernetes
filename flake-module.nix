{projectLib, ...}: {
    lib,
    flake-parts-lib,
    ...
}: {
    options.perSystem = flake-parts-lib.mkPerSystemOption ({
        pkgs,
        config,
        ...
    }: {
        options.n19s = {
            environments = lib.mkOption {
                type = lib.types.lazyAttrsOf (lib.types.submoduleWith {
                    modules = [./modules/environment.nix];
                    specialArgs = {
                        inherit projectLib pkgs;
                        configuration = config.n19s.configuration;
                    };
                });
                default = {};
                description = ''
                    Top-level scope for resource declarations.
                '';
            };

            configuration = lib.mkOption {
                type = lib.types.submodule {
                    options = {
                        resourceTypeRegistry = lib.mkOption {
                            type = lib.types.attrsOf (lib.types.attrsOf lib.types.optionType);
                            description = ''
                                A nested attribute set; a map with first key beeing apiVersion,
                                second key kind, value beeing resource kind submodule type.
                            '';
                            example = ''
                                registry = {
                                "v1".Service          = serviceSubmodule;
                                "apps/v1".Deployment  = lib.types.submodule { ... };
                                };
                            '';
                            default = {};
                        };
                    };
                };
                default = {};
            };
        };

        config.packages = let
            makeFileCopier = {
                fileCopyInstructions, # a list {source: path of the file to be copied; path: path of a file that should be copied}
                applicationName,
            }:
                pkgs.writeShellApplication {
                    name = applicationName;
                    runtimeEnv = {
                        files = pkgs.writers.writeJSON "files.json" fileCopyInstructions;
                    };

                    text = pkgs.writers.writeNu applicationName
                    # nu
                    ''
                        cd (git rev-parse --show-toplevel)

                        for file in (open $env.files) {
                          mkdir ($file.path | path dirname)
                          open --raw $file.source | save -f $file.path
                        }
                    '';

                    derivationArgs = {
                        allowSubstitutes = false;
                        preferLocalBuild = true;
                    };
                };
        in
            (builtins.attrNames config.n19s.environments)
            |> builtins.map
            (name: let
                value = config.n19s.environments.${name};
            in {
                name = "generateManifests-env-${name}";
                value = makeFileCopier {
                    fileCopyInstructions = builtins.map
                    ({
                        path,
                        source,
                        ...
                    }: {
                        inherit path source;
                    })
                    value.build.files;
                    applicationName = "generateManifests-env-${name}";
                };
            })
            |> builtins.listToAttrs;
    });
}
