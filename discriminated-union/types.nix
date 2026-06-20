# Discriminated union type for Kubernetes manifests.
#
# Dispatches to the correct submodule based on (apiVersion, kind).
#
# WHY NOT types.oneOf?
#   types.oneOf is a left-fold of types.either.  Branch selection is driven
#   by each branch's `check` function.  For types.submodule, `check` is
#   intentionally shallow – it returns true for *any* attrset/function/path –
#   so every submodule branch passes for every Kubernetes object.  The first
#   branch always wins, regardless of kind.
#
# THIS APPROACH:
#   A custom mkOptionType that reads (apiVersion, kind) from the raw value
#   and dispatches to the matching submodule's merge function.  The submodule
#   then performs full nested option validation.
{ lib }:

let
  # ── Shared submodule ──────────────────────────────────────────────
  metadataSubmodule = lib.types.submodule {
    options = {
      name = lib.mkOption {
        type = lib.types.str;
        description = "Name of the Kubernetes resource.";
      };
    };
  };


  # ── Service  (apiVersion: v1) ─────────────────────────────────────
  serviceSubmodule = lib.types.submodule {
    options = {
      apiVersion = lib.mkOption {
        type = lib.types.enum [ "v1" ];
        default = "v1";
      };
      kind = lib.mkOption {
        type = lib.types.enum [ "Service" ];
        default = "Service";
      };
      metadata = lib.mkOption {
        type = metadataSubmodule;
      };
      spec = lib.mkOption {
        type = lib.types.submodule {
          options = {
            ports = lib.mkOption {
              type = lib.types.listOf (lib.types.submodule {
                options = {
                  port = lib.mkOption {
                    type = lib.types.int;
                    description = "Port number.";
                  };
                };
              });
              default = [];
              description = "Ports the Service exposes.";
            };
          };
        };
        default = {};
      };
    };
  };


  # ── Deployment  (apiVersion: apps/v1) ────────────────────────────
  deploymentSubmodule = lib.types.submodule {
    options = {
      apiVersion = lib.mkOption {
        type = lib.types.enum [ "apps/v1" ];
        default = "apps/v1";
      };
      kind = lib.mkOption {
        type = lib.types.enum [ "Deployment" ];
        default = "Deployment";
      };
      metadata = lib.mkOption {
        type = metadataSubmodule;
      };
      spec = lib.mkOption {
        type = lib.types.submodule {
          options = {
            replicas = lib.mkOption {
              type = lib.types.int;
              default = 1;
              description = "Number of desired pod replicas.";
            };
          };
        };
        default = {};
      };
    };
  };


  # ── Dispatch registry ─────────────────────────────────────────────
  # Shape:  { "<apiVersion>" = { "<kind>" = <submodule type>; }; }
  # Adding a new resource type = add an entry here + define its submodule.
  registry = {
    "v1".Service          = serviceSubmodule;
    "apps/v1".Deployment  = deploymentSubmodule;
  };

  knownKinds =
    lib.concatStringsSep ", " (
      lib.flatten (
        lib.mapAttrsToList
          (av: kinds: map (k: "${av}/${k}") (lib.attrNames kinds))
          registry
      )
    );


  # ── Custom discriminated-union type ──────────────────────────────

in lib.types.mkOptionType {

  name        = "k8sObject";
  description = "Kubernetes manifest discriminated by apiVersion and kind";

  # Shallow check used by `either`/`oneOf` branch selection.
  # Verifies that the (apiVersion, kind) pair is registered.
  check = v:
    lib.isAttrs v
    && v ? apiVersion && builtins.isString v.apiVersion
    && v ? kind       && builtins.isString v.kind
    && lib.hasAttrByPath [ v.apiVersion v.kind ] registry;

  # ALWAYS CALLED - even when only single value is assigned to it.
  # the submoduleType.merge run validation of submodule specific options
  # and defers further validation on options value access
  # 
  # Dispatch: extract (apiVersion, kind), look up the submodule, delegate.
  # `listOf` calls `elemType.merge` directly (without calling `check` first),
  # so `merge` must also guard against unknown types.
  merge = loc: defs:
    let
      firstVal   = (builtins.head defs).value;
      apiVersion = firstVal.apiVersion or null;
      kind       = firstVal.kind or null;

      # All co-located defs must agree on the discriminator.
      conflicts  = lib.filter
        (def:
          def.value.apiVersion or null != apiVersion
          || def.value.kind or null != kind
        )
        (builtins.tail defs);

      submoduleType =
        if lib.hasAttrByPath [ apiVersion kind ] registry
        then registry.${apiVersion}.${kind}
        else throw
          "k8sObject: unknown type apiVersion=${toString apiVersion}, kind=${toString kind}"
          + " at option `${lib.showOption loc}`."
          + " Known types: ${knownKinds}";
    in
    if conflicts != []
    then throw "k8sObject: conflicting apiVersion/kind values at `${lib.showOption loc}`"
    else submoduleType.merge loc defs;
}
