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
            resourceSet = {
                pkgs,
                configuration,
            }:
                lib.types.oneOf [
                    (resourceSetBody {inherit pkgs configuration;})
                    (lib.types.functionTo (resourceSetBody {inherit pkgs configuration;}))
                ];

            resourceSetBody = {
                pkgs,
                configuration,
            }:
                lib.types.submoduleWith {
                    modules = [./resourceSet.nix];
                    specialArgs = {
                        inherit pkgs configuration;
                        projectLib = config.projectLib;
                    };
                };

            resource = {
                # a nested attribute set; a map with first key beeing apiVersion,
                # second key kind, value beeing resource kind submodule type.
                # for example:
                # ```
                # registry = {
                #   "v1".Service          = serviceSubmodule;
                #   "apps/v1".Deployment  = deploymentSubmodule;
                # };
                # ```
                registry,
            }:
                lib.types.mkOptionType {
                    name = "resource";
                    description = "Kubernetes manifest discriminated by apiVersion and kind";

                    # Verifies that the (apiVersion, kind) pair is registered.
                    check = v:
                        lib.isAttrs v
                        && v ? apiVersion
                        && builtins.isString v.apiVersion
                        && v ? kind
                        && builtins.isString v.kind
                        && lib.hasAttrByPath [v.apiVersion v.kind] registry;

                    # ALWAYS CALLED - even when only single value is assigned to it.
                    # the submoduleType.merge run validation of submodule specific options
                    # and defers further validation on options value access
                    #
                    # Dispatch: extract (apiVersion, kind), look up the submodule, delegate.
                    # `listOf` calls `elemType.merge` directly (without calling `check` first),
                    # so `merge` must also guard against unknown types.
                    merge = loc: defs: let
                        firstVal = (builtins.head defs).value;
                        apiVersion = firstVal.apiVersion or null;
                        kind = firstVal.kind or null;

                        # All co-located defs must agree on the discriminator.
                        conflicts = lib.filter
                        (
                            def:
                                def.value.apiVersion or null
                                != apiVersion
                                || def.value.kind or null != kind
                        )
                        (builtins.tail defs);

                        submoduleType =
                            if lib.hasAttrByPath [apiVersion kind] registry
                            then registry.${apiVersion}.${kind}
                            else
                                throw
                                "resource: unknown type apiVersion=${toString apiVersion}, kind=${toString kind}"
                                + " at option `${lib.showOption loc}`.";
                    in
                        if conflicts != []
                        then throw "resource: conflicting apiVersion/kind values at `${lib.showOption loc}`"
                        else submoduleType.merge loc defs;
                };
        };
    };
}
