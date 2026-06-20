# Kubernetes Resource Nix Type Definitions

Resources are attrset values in a list. To validate them with the Nix module
system, each element must be checked against a schema selected by its own
`apiVersion` and `kind` fields — a discriminated union.

See [ADR 01 — Discriminated Union Option Type](../adr/01-Discriminated_Union_Option_Type.md)
for the rationale and why `types.oneOf` does not work here.

## How it works

The `resources` option uses a custom `k8sResource` type:

```nix
options.resources = lib.mkOption {
  type = lib.types.listOf k8sk8sResourceType;
};
```

For each list element the type does two things:

1. **`check`** — confirms `(apiVersion, kind)` is registered. A missing entry
   produces a "not of type" error immediately, before any submodule is touched.

2. **`merge`** — looks up the matching submodule and calls its `merge`. The
   specific resource submodule (declaring resource specific options) handles
   everything else: applying defaults, enforcing required fields, and
   validating nested option types.

## Adding a resource type

Define a submodule and add one entry to the registry in
`discriminated-union/types.nix`:

```nix
# 1. submodule
configMapSubmodule = lib.types.submodule {
  options = {
    apiVersion = lib.mkOption { type = lib.types.enum [ "v1" ]; default = "v1"; };
    kind       = lib.mkOption { type = lib.types.enum [ "ConfigMap" ]; default = "ConfigMap"; };
    metadata   = lib.mkOption { type = metadataSubmodule; };
    data       = lib.mkOption { type = lib.types.attrsOf lib.types.str; default = {}; };
  };
};

# 2. registry entry
registry = {
  "v1".Service    = serviceSubmodule;
  "v1".ConfigMap  = configMapSubmodule;  # ← new
  "apps/v1".Deployment = deploymentSubmodule;
};
```

## Note on `group`

Standard Kubernetes manifests have no separate `group` field. The group is the
prefix of `apiVersion` (`apps` in `apps/v1`; core resources use a bare version
like `v1`). The registry key `apiVersion` therefore covers both group and version.
