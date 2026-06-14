{
    lib,
    projectLib,
    name,
    ...
}: {
    options = {
        /*
    Draft scopes / graph fragments.
    */
        resourceSets = lib.mkOption {
            type = lib.types.attrsOf projectLib.resourceSetType;
            default = {};
            description = ''
                Reusable resource draft scopes. Each resource set may be a plain module body
                or a function receiving a reference context and returning a module body.

                Used for:
                - definition a set of resources which are used in multiple places
                - apply transformation/normalizations on a set of resources
            '';
        };

        /*
    Final rendered scopes.
    */
        scopes = lib.mkOption {
            type = lib.types.attrsOf projectLib.resourceSetType;
            default = {};
            description = ''
                Rendered output scopes. These instantiate resource sets, bind refs,
                apply final transforms, and produce YAML output.
            '';
        };

        outputConfig = {
            directoryName = lib.mkOption {
                type = lib.types.str;
                default = name;

                description = ''
                    Name of the output directory for this environment.
                '';
            };

            nestingLayout = lib.mkOption {
                type = lib.types.listOf lib.types.enum [
                    "by-scope"
                    "by-namespace"
                    "by-kind"
                ];
                default = [];

                description = ''
                    How nesting layout of the output directory should be structured.
                    Each nesting layout option corresponds to a directory level.
                    When multiple options are specified, they are applied in order of 'by-scope', 'by-namespace', 'by-kind'.
                '';
            };
        };

        build = lib.mkOption {
            type = lib.types.submodule {
                options = {
                    resources = lib.mkOption {
                        type = lib.types.attrsOf lib.types.anything;
                        default = {};
                    };

                    files = lib.mkOption {
                        type = lib.types.listOf (lib.types.submodule {
                            freeformType = lib.types.attrsOf lib.types.anything;

                            options.source = lib.mkOption {
                                type = lib.types.str;
                                description = "File path";
                            };
                        });
                    };
                };
            };

            visible = false;
            readOnly = true;
        };
    };
    config = {
        # build.resources = {};
    };
}
