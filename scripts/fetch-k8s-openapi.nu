#!/usr/bin/env nu

def main [
  version: string          # e.g. v1.33.0, v1.32.4
  out_dir: path            # destination directory
  --include-prerelease(-p) # include v1alpha1 / v1beta1 files too
] {
  let ref = if ($version =~ '^\d+\.\d+\.\d+$') {
    $"v($version)"
  } else {
    $version
  }

  let api_url = $"https://api.github.com/repos/kubernetes/kubernetes/contents/api/openapi-spec/v3?ref=($ref)"

  mkdir $out_dir

  let stable_manifest_file_re = '^(api__v[0-9]+|apis__.+__v[0-9]+)_openapi\.json$'
  let all_manifest_file_re = '^(api__v[0-9]+(?:alpha[0-9]+|beta[0-9]+)?|apis__.+__v[0-9]+(?:alpha[0-9]+|beta[0-9]+)?)_openapi\.json$'

  let file_re = if $include_prerelease {
    $all_manifest_file_re
  } else {
    $stable_manifest_file_re
  }

  let files = (
    http get $api_url
    | where type == "file"
    | where name =~ $file_re
    | sort-by name
  )

  if (($files | length) == 0) {
    error make {
      msg: $"No matching OpenAPI v3 files found for Kubernetes ref: ($ref)"
    }
  }

  print $"Found (($files | length)) matching OpenAPI v3 files for ($ref)"

  for f in $files {
    let target = ([$out_dir $f.name] | path join)

    http get --raw $f.download_url | save --force $target
  }

  print $"Done. Files written to: ($out_dir)"
}