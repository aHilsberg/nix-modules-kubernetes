

## Files

| File | Purpose |
|------|---------|
| `types.nix` | `k8sObject` discriminated union type + submodule definitions |
| `module.nix` | Minimal module: `options.resources = listOf k8sObject` |
| `eval.nix` | No-flake evaluation entry point with test data |

## Running

```bash
# Evaluate and print validated config as JSON
nix eval -f eval.nix --json

# With full error traces
nix eval -f eval.nix --json --show-trace
```

## Verified Behaviour

### Happy path (eval.nix)

```json
[
  { "apiVersion": "v1",      "kind": "Service",    "metadata": { "name": "nginx" },
    "spec": { "ports": [{ "port": 80 }, { "port": 443 }] } },
  { "apiVersion": "apps/v1", "kind": "Deployment", "metadata": { "name": "nginx" },
    "spec": { "replicas": 3 } },
  { "apiVersion": "apps/v1", "kind": "Deployment", "metadata": { "name": "api"   },
    "spec": { "replicas": 1 } }   ← default applied
]
```

### Error: wrong field type

```nix
spec.ports = [{ port = "not-a-number"; }]
```
```
error: A definition for option `resources...port' is not of type `signed integer'.
```

### Error: unknown kind (check fails)

```nix
{ apiVersion = "v1"; kind = "ConfigMap"; ... }
```
```
error: A definition for option `resources...' is not of type
       `Kubernetes manifest discriminated by apiVersion and kind'.
```

### Error: missing required field

```nix
{ apiVersion = "v1"; kind = "Service"; spec.ports = [...]; }
# metadata.name omitted
```
```
error: The option `name' was accessed but has no value defined.
```

## Extending: Adding a New Resource Type

1. Define the submodule:

```nix
configMapSubmodule = lib.types.submodule {
  options = {
    apiVersion = lib.mkOption { type = lib.types.enum [ "v1" ]; default = "v1"; };
    kind       = lib.mkOption { type = lib.types.enum [ "ConfigMap" ]; default = "ConfigMap"; };
    metadata   = lib.mkOption { type = metadataSubmodule; };
    data       = lib.mkOption { type = lib.types.attrsOf lib.types.str; default = {}; };
  };
};
```

2. Add one line to the registry in `types.nix`:

```nix
registry = {
  "v1".Service    = serviceSubmodule;
  "v1".ConfigMap  = configMapSubmodule;   # ← new
  "apps/v1".Deployment = deploymentSubmodule;
};
```
