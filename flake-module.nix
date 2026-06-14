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
                    specialArgs = {inherit projectLib;};
                });
                default = {};
                description = ''
                    Top-level scope for resource declarations.
                '';
            };
        };

        config.packages = builtins.listToAttrs (
            builtins.map
            (name: let
                value = config.n19s.environments.${name};
            in {
                name = "generateManifests-env-${name}";
                value = pkgs.writeShellApplication {
                    name = "generateManifests-env-${name}";
                    runtimeEnv = {
                        files = pkgs.writers.writeJSON "files.json" (
                            builtins.map
                            ({
                                path,
                                source,
                                ...
                            }: {
                                inherit path source;
                            })
                            value.build.files
                        );
                    };

                    text = pkgs.writers.writeNu "generateManifests-env-${name}"
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
            })
            (builtins.attrNames config.n19s.environments)
        );
    });
}
