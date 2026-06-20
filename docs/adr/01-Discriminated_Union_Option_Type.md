# ADR 01 — Discriminated Union Option Type

How to implement a discriminated union type in the Nix module system for
Kubernetes resource manifests, where the shape of each object is determined by
its `apiVersion` and `kind` fields.

## Why not `types.oneOf`

```nix
type = lib.types.listOf (lib.types.oneOf [ deploymentType serviceType ]);
```

`types.oneOf` is a left-fold of `types.either`. Branch selection is driven by
each branch's `check` function. For `types.submodule`, `check` is intentionally
shallow — it returns `true` for any attrset — so **every branch matches every
manifest**. The first branch always wins regardless of `kind`, producing wrong
defaults, confusing errors, and order-dependent behaviour.

## Decision: explicit dispatch via `mkOptionType`

A custom type reads `(apiVersion, kind)` from the raw value and routes to the
correct submodule.

### `check` — branch selection and unknown-kind errors

```nix
check = v:
  lib.isAttrs v
  && v ? apiVersion && builtins.isString v.apiVersion
  && v ? kind       && builtins.isString v.kind
  && lib.hasAttrByPath [ v.apiVersion v.kind ] registry;
```

Only inspects the two discriminator fields. Returns `false` for any
`(apiVersion, kind)` pair not in the registry, which causes the module system
to emit:

```
A definition for option `resources...' is not of type '<type description>'.
```

### `merge` — delegation to the submodule

```nix
merge = loc: defs:
  ...
  submoduleType.merge loc defs;
```

`merge` is always called — including for a single list element — because
`listOf` calls `elemType.merge` directly, bypassing `check`. It looks up the
registered submodule and delegates unconditionally. The submodule's `merge`
then runs full option validation: type checks, defaults, missing-required-field
errors. Nothing is validated in `k8sObjectType.merge` itself beyond the
`(apiVersion, kind)` lookup.