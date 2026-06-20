# Evaluation entry point – no flake required.
#
# Run:
#   nix eval -f eval.nix --json           (structured output)
#   nix-instantiate --eval --strict eval.nix
#
# The expression evaluates to the validated config.resources list.
# Each object is passed through the matching submodule, so:
#   - missing required fields  → evaluation error naming the option
#   - wrong field types        → evaluation error with type description
#   - unknown apiVersion/kind  → explicit error listing known types

let
  pkgs = import <nixpkgs> {};
  lib  = pkgs.lib;

  result = lib.evalModules {
    modules = [
      ./module.nix

      # ── Valid examples ────────────────────────────────────────────
      {
        resources = [

          # Service – validated against serviceSubmodule
          {
            apiVersion = "v1";
            kind       = "Service";
            metadata.name = "nginx";
            spec.ports = [ { port = 80; } { port = 443; } ];
          }

          # Deployment – validated against deploymentSubmodule
          {
            apiVersion = "apps/v1";
            kind       = "Deployment";
            metadata.name = "nginx";
            spec.replicas = 3;
          }

          # Deployment with default replicas (spec.replicas defaults to 1)
          {
            apiVersion = "apps/v1";
            kind       = "Deployment";
            metadata.name = "api";
            # spec omitted → defaults applied: { replicas = 1; }
          }

        ];
      }
    ];
  };
in
result.config.resources
