{lib, ...}: rec {
    types = rec {
        function =
            types.addCheck types.raw builtins.isFunction
            // {
                name = "function";
                description = "function";
            };

        apiKind = lib.types.submodule {
            options = {
                apiVersion = lib.mkOption {
                    type = types.nullOr lib.types.str;
                    default = null;
                    description = ''
                        K8s resource apiVersion.
                    '';
                };

                kind = lib.mkOption {
                    type = types.nullOr types.str;
                    default = null;
                    description = ''
                        K8s resource kind.
                    '';
                };
            };
        };

        resourceSelector = lib.types.submodule {
            options = {
                apiVersion = lib.mkOption {
                    type = types.nullOr lib.types.str;
                    default = null;
                    description = ''
                        Selection based on equality of kubernetes apiVersion.
                    '';
                };

                kind = lib.mkOption {
                    type = types.nullOr types.str;
                    default = null;
                };

                name = lib.mkOption {
                    type = types.nullOr types.str;
                    default = null;
                    description = ''
                        Selection based on equality of kubernetes metadata.name.
                    '';
                };

                namespace = lib.mkOption {
                    type = types.nullOr types.str;
                    default = null;
                    description = ''
                        Selection based on equality of kubernetes namespace.
                    '';
                };

                labels = lib.mkOption {
                    type = types.attrsOf types.str;
                    default = {};
                    description = ''
                        Selection based on equality of kubernetes labels.
                    '';
                };

                annotations = lib.mkOption {
                    type = types.attrsOf types.str;
                    default = {};
                    description = ''
                        Selection based on equality of kubernetes annotations.
                    '';
                };
            };
        };

        referenceType = types.types.submodule {
            options = {
                __kind = lib.mkOption {
                    type = apiKind;
                };

                selector = lib.mkOption {
                    type = resourceSelector;
                };

                # TOOD scope reference?
            };
        };

        referencesDeclaration = let
            nestedAttrsOf = elemType: let
                tree = types.lazyAttrsOf (types.either elemType tree);
            in
                tree;
        in
            nestedAttrsOf referenceType;

        # A list of nix values of resources, returning a list of nix values of resources
        transform = function;

        /*
    A resource set can be written either as:

        resourceSets.foo = {
        ...
        };

    or:

        resourceSets.foo = { refs, ref, ... }: {
        ...
        };

    The function form is intentionally not resolved by this module.
    The compiler applies it later with a reference context.
    */
        resourceSet = lib.types.oneOf [
            resourceSetBody
            (lib.types.functionTo resourceSetBody)
        ];

        resourceSetBody = lib.types.submodule ({...}: {
            options = {
                /*
        Native / generated resources.

        Shape:

        resources.v1.app-config = { ... };
        resources.admissionregistration.k8s.io.gateway-hook = { ... };

        or

        resources = [{
            apiVersion: ...;
            kind: ....;
        }]

        The first level is a Nix grouping key, not a Kubernetes API contract.
        */
                resources = lib.mkOption {
                    # todo
                    type = lib.types.attrsOf (lib.types.attrsOf lib.types.anything);
                    default = {};
                };

                sources = {
                    /*
          Raw YAML inputs. These are normalized into draft resources before
          registry construction.
          */
                    rawYaml = lib.mkOption {
                        type = lib.types.listOf lib.types.path;
                        default = {};
                    };

                    /*
          Helm chart inputs.
          */
                    # TODO
                    helm = lib.mkOption {
                        type = lib.types.listOf lib.types.anything;
                        default = {};
                    };

                    /*
          ResourceSets and Scope objects
          */
                    includedResourceSets = lib.mkOption {
                        type = lib.types.listOf lib.types.anything;
                        default = {};
                    };
                };

                /*
        Local resource-set transforms.
        */
                transforms = lib.mkOption {
                    type = transform;
                    default = {};
                };

                /*
        Referencable Declaration
        */
                referencable = lib.mkOption {
                    type = referencesDeclaration;
                    default = {};
                };
            };
        });
    };
}
