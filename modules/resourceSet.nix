{
    lib,
    config,
    pkgs,
    ...
}: {
    options = {
        resources = lib.mkOption {
            # todo
            type = lib.types.listOf lib.types.anything;
            default = {};
            description = "K8s resource manifests specified in nix";
            example = ''
                resources = [{
                    apiVersion: ...;
                    kind: ....;
                }]
            '';
        };

        # sources = {
        #   /*
        #   Raw YAML inputs. These are normalized into draft resources before
        #   registry construction.
        #   */
        #   rawYaml = lib.mkOption {
        #     type = lib.types.listOf lib.types.path;
        #     default = {};
        #   };

        #   /*
        #   Helm chart inputs.
        #   */
        #   # TODO
        #   helm = lib.mkOption {
        #     type = lib.types.listOf lib.types.anything;
        #     default = {};
        #   };

        #   /*
        #   ResourceSets and Scope objects
        #   */
        #   includedResourceSets = lib.mkOption {
        #     type = lib.types.listOf lib.types.anything;
        #     default = {};
        #   };
        # };

        # /*
        # Local resource-set transforms.
        # */
        # transforms = lib.mkOption {
        #   type = transform;
        #   default = {};
        # };

        # /*
        # Referencable Declaration
        # */
        # referencable = lib.mkOption {
        #   type = referencesDeclaration;
        #   default = {};
        # };

        build = lib.mkOption {
            type = lib.types.submodule {
                options = {
                    resources = lib.mkOption {
                        type = lib.types.listOf lib.types.anything;
                        default = {};
                        description = "Resource manifests in nix value form, from all sources and after transformation";
                    };

                    files = lib.mkOption {
                        type = lib.types.listOf (lib.types.submodule {
                            options = {
                                source = lib.mkOption {
                                    type = lib.types.either lib.types.package lib.types.pathInStore;
                                };
                                value = lib.mkOption {
                                    type = lib.types.anything;
                                    description = "Resource value";
                                };
                                path = lib.mkOption {
                                    type = lib.types.str;
                                    description = "File path";
                                };
                            };
                        });
                        description = "List of resource descriptions that have been serialized to files";
                    };
                };
            };

            internal = true;
            visible = false;
            readOnly = true;
        };
    };

    config.build = {
        resources = config.resources;

        files = builtins.map
        (resource: {
            source = (pkgs.formats.yaml {}).generate "manifest.yaml" resource;
            value = resource;
            path = lib.concatStringsSep "-" (
                [resource.kind]
                ++ lib.optional (resource.metadata.namespace or null != null) resource.metadata.namespace
                ++ [resource.metadata.name]
            );
        })
        config.build.resources;
    };
}
