#!/usr/bin/env nu

def main [min_major: number, min_minor: number] {
  generate {|page|
    let batch = (
      http get $"https://api.github.com/repos/kubernetes/kubernetes/tags?per_page=100&page=($page)"
    )

    if ($batch | is-empty) {
      {out: []}
    } else {
      {out: $batch, next: ($page + 1)}
    }
  } 0
  | flatten # flatten the batch into a single list
  | get name
  | where {|v|
      # filter out sub versions like -alpha, beta ...
      if not ($v =~ '^v\d+\.\d+\.\d+$') {
        false
      } else {
        let parts = ($v | str replace -r '^v' '' | split row '.' | into int)
        let major = ($parts | get 0)
        let minor = ($parts | get 1)
  
        $major > $min_major or ($major == $min_major and $minor >= $min_minor)
      }
    }
  | sort --natural
  | reverse
  | to json
}