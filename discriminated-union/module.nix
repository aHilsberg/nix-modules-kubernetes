{lib, ...}: let
    k8sObjectType = import ./types.nix {inherit lib;};
in {
    options.resources = lib.mkOption {
        type = lib.types.listOf k8sObjectType;
        default = [];
        description = ''
            List of Kubernetes resource manifests.
            Each entry is validated against the submodule schema for its
            (apiVersion, kind) combination.
        '';
    };
}
