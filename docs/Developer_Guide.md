
## Project Structure and Option Levels

The module system is organized in layers, each scoped to a specific concern. Options are declared at the appropriate level and pass their evaluated values downward via `specialArgs`.

```
nix-module-kubernetes/
├── flake.nix                   # Wires everything together; auto-imports all .lib.nix files
├── lib.nix                     # Declares the top-level `projectLib` option and module arg
├── flake-module.nix            # Exported Module: Declares the public-facing perSystem options (n19s.*)
│
└── modules/
    ├── types.lib.nix           # projectLib contribution: shared primitive types
    ├── resourceSet.lib.nix     # projectLib contribution: resourceSet + resource types
    ├── resourceSet.nix         # submodule for a set of resources (from different sources: yaml, helm, ...)
    ├── environment.nix         # submodule for a single environment (resourceSets, outputConfig, build)
    └── resources.nix           # submodule for individual resource declarations
```

Each level receives `projectLib`, `pkgs`, and any parent-level config it needs through `specialArgs`, keeping concerns cleanly separated without global imports.

---

## projectLib

`projectLib` is the project's internal shared library — a single attribute set that accumulates types and helpers contributed by every `.lib.nix` file.

### How it is built

`lib.nix` declares the `projectLib` option on the flake-parts module system:

```nix
# lib.nix
options.projectLib = lib.mkOption {
    type = lib.types.submodule {
        freeformType = lib.types.lazyAttrsOf lib.types.anything;
    };
    default = {};
};

config._module.args.projectLib = config.projectLib;
```

`flake.nix` then auto-imports every file whose name ends in `.lib.nix` from the `modules/` directory using `import-tree`:

```nix
(inputs.import-tree .filter (path: lib.hasSuffix ".lib.nix" path) ./modules)
```

Because all `.lib.nix` files are regular flake-parts modules, they receive `lib`, `config`, and the `projectLib` module arg automatically. Each file contributes to `projectLib` by setting attributes under it — the module system merges all contributions into one coherent value.

### What it contains

Each `.lib.nix` file declares what it contributes under `projectLib`:

- **`modules/types.lib.nix`** — primitive shared types: `function`, `apiKind`, `resourceSelector`, `referenceType`, `referencesDeclaration`, `transform`.
- **`modules/resourceSet.lib.nix`** — higher-level types that depend on runtime args (`pkgs`, `configuration`): `resourceSet`, `resourceSetBody`, and the discriminated `resource` type (dispatches to the correct submodule via the `apiVersion`/`kind` registry).

### How it flows through the layers

```
lib.nix  ──declares──►  config.projectLib  (merged from all .lib.nix modules)
                              │
                              │  passed as specialArg
                              ▼
                      flake-module.nix
                      (kubernetesFlakeModule receives projectLib directly)
                              │
                              │  specialArgs = { inherit projectLib pkgs configuration; }
                              ▼
                      modules/environment.nix
                      (uses projectLib.types.resourceSet)
                              │
                              │  specialArgs = { inherit pkgs configuration; projectLib = config.projectLib; }
                              ▼
                      modules/resourceSet.nix
                      (uses projectLib.types.resource)
```

Because `projectLib` is itself a merged module option, adding a new `.lib.nix` file automatically extends it without touching any other file.

---

## Debuging

```bash
nix eval .\#inspectable.x86_64-linux.testModule-nixResouceToYaml.allSystems.x86_64-linux.n19s
```

