{
    lib,
    config,
    ...
}: {
    projectLib = {
        types = rec {
            # A resource set can be written either as:
            # resourceSets.foo = {
            # ...
            # };
            #
            # or:
            #
            # resourceSets.foo = { refs, ref, ... }: {
            # ...
            # };
            # The function form is intentionally not resolved by this module.
            # The compiler applies it later with a reference context.
            resourceSet = {pkgs}:
                lib.types.oneOf [
                    (resourceSetBody {inherit pkgs;})
                    (lib.types.functionTo (resourceSetBody {inherit pkgs;}))
                ];

            resourceSetBody = {pkgs}:
                lib.types.submoduleWith {
                    modules = [./resourceSet.nix];
                    specialArgs = {
                        projectLib = config.projectLib;
                        pkgs = pkgs;
                    };
                };
        };
    };
}
