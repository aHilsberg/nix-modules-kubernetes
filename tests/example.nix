{
    inputs,
    config,
    flake-parts-lib,
    ...
}: {
    flake.modules.flake.nixResouceToYaml = {...}: {
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
                
                outputConfig = {
                    directoryName = "tests/snapshots/nixResouce_producesExpectedYaml";
                    nestingLayout = []; # flat
                };
            };
        };
    };

    transposition.inspectable.adHoc = true;
    perSystem = {system, ...}: {
        inspectable.testModule-nixResouceToYaml =
            (
                flake-parts-lib.evalFlakeModule
                {inherit inputs;}
                {
                    imports = [
                        config.flake.flakeModule
                        config.flake.modules.flake.nixResouceToYaml
                    ];
                    systems = [
                        "x86_64-linux"
                    ];
                    debug = true;
                }
            ).config.flake;

        packages.generate-test-nixResouce_producesExpectedYaml =
            (
                flake-parts-lib.mkFlake
                {inherit inputs;}
                {
                    imports = [
                        config.flake.flakeModule
                        config.flake.modules.flake.nixResouceToYaml
                    ];
                    systems = [system];
                }
            ).packages.${
                system
            }.generateManifests-env-testing;
    };

    # flake.modules.dogfoot.tmp = {lib, ...}: {
    #     resourceSets.gateway = {...}: {
    #         resources.gateways.edge = {
    #             apiVersion = "gateway.networking.k8s.io/v1";
    #             kind = "Gateway";

    #             metadata.name = "edge";

    #             sections.listeners.https.value = {
    #                 name = "https";
    #                 port = 443;
    #                 protocol = "HTTPS";
    #             };
    #         };

    #         references.public.listeners.https = lib.kube.reference.gatewayListener {
    #             resourceSelector = {
    #                 path = ["resources" "gateways" "edge"];
    #             };

    #             sectionSelector = {
    #                 path = ["sections" "listeners" "https"];
    #                 sectionType = "GatewayListener";
    #                 field = ["spec" "listeners"];
    #             };
    #         };
    #     };
    #     resourceSets.routes = {refs, ...}: {
    #         inputs.gateway.publicHttps = lib.kube.input {
    #             expected = {
    #                 apiVersion = "gateway.networking.k8s.io/v1";
    #                 kind = "Gateway";
    #                 sectionType = "GatewayListener";
    #                 namespaceMode = "explicit";
    #             };

    #             acceptedRenderAs = ["HTTPRouteParentRef"];
    #         };

    #         resources.httpRoutes.app = {
    #             apiVersion = "gateway.networking.k8s.io/v1";
    #             kind = "HTTPRoute";

    #             metadata.name = "app";

    #             spec.parentRefs = [
    #                 refs.gateway.publicHttps
    #             ];
    #         };
    #     };

    #     scopes.edge = {
    #         namespace = "gateway-system";

    #         resourceSets = [
    #             {
    #                 name = "gateway";
    #                 alias = "gateway";
    #             }

    #             {
    #                 name = "routes";

    #                 refs.gateway.publicHttps = lib.kube.renderRefPath {
    #                     path = [
    #                         "scopes"
    #                         "edge"
    #                         "instances"
    #                         "gateway"
    #                         "references"
    #                         "public"
    #                         "listeners"
    #                         "https"
    #                     ];

    #                     renderAs = "HTTPRouteParentRef";
    #                 };
    #             }
    #         ];
    #     };
    # };
}
