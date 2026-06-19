{
    inputs,
    config,
    flake-parts-lib,
    ...
}: {
    flake.modules.flake.fileGeneration = {...}: {
        perSystem = {
            n19s.environments.testing = {
                resourceSets.gateway = {...}: {
                    resources = [
                        {
                            apiVersion = "gateway.networking.k8s.io/v1";
                            kind = "Gateway";

                            metadata.name = "edge";

                            sections.listeners.https.value = {
                                name = "https";
                                port = 443;
                                protocol = "HTTPS";
                            };
                        }
                    ];
                };
            };
        };
    };

    perSystem = {system, ...}: {
        packages.generate-test-flatLayout_generatesExpectedFiles =
            (
                flake-parts-lib.mkFlake
                {inherit inputs;}
                {
                    imports = [
                        config.flake.flakeModule
                        config.flake.modules.flake.fileGeneration
                    ];
                    systems = [system];

                    perSystem = {
                        n19s.environments.testing = {
                            outputConfig = {
                                directoryName = "tests/snapshots/flatLayout_generatesExpectedFiles";
                                nestingLayout = []; # flat
                            };
                        };
                    };
                }
            ).packages.${
                system
            }.generateManifests-env-testing;

        packages.generate-test-byKindLayout_generatesExpectedFiles =
            (
                flake-parts-lib.mkFlake
                {inherit inputs;}
                {
                    imports = [
                        config.flake.flakeModule
                        config.flake.modules.flake.fileGeneration
                    ];
                    systems = [system];

                    perSystem = {
                        n19s.environments.testing = {
                            outputConfig = {
                                directoryName = "tests/snapshots/byKindLayout_generatesExpectedFiles";
                                nestingLayout = [
                                    "by-kind"
                                ];
                            };
                        };
                    };
                }
            ).packages.${
                system
            }.generateManifests-env-testing;

        packages.generate-test-byNamespaceLayout_generatesExpectedFiles =
            (
                flake-parts-lib.mkFlake
                {inherit inputs;}
                {
                    imports = [
                        config.flake.flakeModule
                        config.flake.modules.flake.fileGeneration
                    ];
                    systems = [system];

                    perSystem = {
                        n19s.environments.testing = {
                            outputConfig = {
                                directoryName = "tests/snapshots/byNamespaceLayout_generatesExpectedFiles";
                                nestingLayout = [
                                    "by-namespace"
                                ];
                            };
                        };
                    };
                }
            ).packages.${
                system
            }.generateManifests-env-testing;

        # TODO
        # packages.generate-test-byScopeLayout_generatesExpectedFiles =
        #     (
        #         flake-parts-lib.mkFlake
        #         {inherit inputs;}
        #         {
        #             imports = [
        #                 config.flake.flakeModule
        #                 config.flake.modules.flake.fileGeneration
        #             ];
        #             systems = [system];

        # perSystem = {
        #     n19s.environments.testing = {
        #             outputConfig = {
        #                 directoryName = "tests/snapshots/flatLayout_generatesExpectedFiles";
        #                 nestingLayout = [
        #                     "by-scope"
        #                 ];
        #             };
        #     };
        # };
        #         }
        #     ).packages.${
        #         system
        #     }.generateManifests-env-testing;

        packages.generate-test-combinedLayout_generatesExpectedFiles =
            (
                flake-parts-lib.mkFlake
                {inherit inputs;}
                {
                    imports = [
                        config.flake.flakeModule
                        config.flake.modules.flake.fileGeneration
                    ];
                    systems = [system];

                    perSystem = {
                        n19s.environments.testing = {
                            outputConfig = {
                                directoryName = "tests/snapshots/combinedLayout_generatesExpectedFiles";
                                nestingLayout = [
                                    "by-namespace"
                                    "by-kind"
                                ];
                            };
                        };
                    };
                }
            ).packages.${
                system
            }.generateManifests-env-testing;
    };
}
