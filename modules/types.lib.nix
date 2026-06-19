{lib, ...}: {
    projectLib = {
        types = rec {
            function =
                lib.types.addCheck lib.types.raw builtins.isFunction
                // {
                    name = "function";
                    description = "function";
                };

            apiKind = lib.types.submodule {
                options = {
                    apiVersion = lib.mkOption {
                        type = lib.types.nullOr lib.types.str;
                        default = null;
                        description = ''
                            K8s resource apiVersion.
                        '';
                    };

                    kind = lib.mkOption {
                        type = lib.types.nullOr lib.types.str;
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
                        type = lib.types.nullOr lib.types.str;
                        default = null;
                        description = ''
                            Selection based on equality of kubernetes apiVersion.
                        '';
                    };

                    kind = lib.mkOption {
                        type = lib.types.nullOr lib.types.str;
                        default = null;
                    };

                    name = lib.mkOption {
                        type = lib.types.nullOr lib.types.str;
                        default = null;
                        description = ''
                            Selection based on equality of kubernetes metadata.name.
                        '';
                    };

                    namespace = lib.mkOption {
                        type = lib.types.nullOr lib.types.str;
                        default = null;
                        description = ''
                            Selection based on equality of kubernetes namespace.
                        '';
                    };

                    labels = lib.mkOption {
                        type = lib.types.attrsOf lib.types.str;
                        default = {};
                        description = ''
                            Selection based on equality of kubernetes labels.
                        '';
                    };

                    annotations = lib.mkOption {
                        type = lib.types.attrsOf lib.types.str;
                        default = {};
                        description = ''
                            Selection based on equality of kubernetes annotations.
                        '';
                    };
                };
            };

            referenceType = lib.types.submodule {
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
                    tree = lib.types.lazyAttrsOf (lib.types.either elemType tree);
                in
                    tree;
            in
                nestedAttrsOf referenceType;

            # A list of nix values of resources, returning a list of nix values of resources
            transform = function;
        };
    };
}
