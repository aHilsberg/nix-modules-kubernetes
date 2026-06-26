
# Update

## New Kubernetes Version published

```nu
./scripts/fetch-k8s-versions.nu 1 29 | save -f ./generated/k8s/versions.json
open ./generated/k8s/versions.json | each {|v| ./scripts/fetch-k8s-openapi.nu $v | save -f $"./generated/k8s/spec-($v).json" }
```

