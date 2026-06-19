# project-lib-base.nix
{
    lib,
    config,
    ...
}: {
    options.projectLib = lib.mkOption {
        type = lib.types.submodule {
            freeformType = lib.types.lazyAttrsOf lib.types.anything;
        };
        default = {};

        description = "Project-local shared library";
    };

    config = {
        _module.args.projectLib = config.projectLib;
    };
}
