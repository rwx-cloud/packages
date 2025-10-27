#!/usr/bin/env bash

set -euo pipefail

usage() {
  echo "Usage: $0 <container> <output_dir>"
  echo "Example: $0 my-running-container ./env_out"
  exit 1
}

[[ $# -eq 2 ]] || usage
CONTAINER="$1"
OUTDIR="$2"

# Ensure docker is available
if ! command -v docker >/dev/null 2>&1; then
  echo "Error: docker is not installed or not in PATH." >&2
  exit 2
fi

# Verify container exists (running or not)
if ! docker container inspect "$CONTAINER" >/dev/null 2>&1; then
  echo "Error: container '$CONTAINER' not found." >&2
  exit 2
fi

# Read env lines from the container's Config.Env (initial env at container start)
get_env_lines() {
  if docker container inspect --format '{{range .Config.Env}}{{println .}}{{end}}' "$CONTAINER" 2>/dev/null; then
    return 0
  fi
  if command -v jq >/dev/null 2>&1; then
    docker container inspect "$CONTAINER" | jq -r '.[0].Config.Env[]?'
  else
    echo "Error: Failed to read env from container and jq not available." >&2
    return 1
  fi
}

while IFS= read -r line; do
  [[ -n "$line" ]] || continue
  echo "$line"

  # Split on first '=' only
  key=${line%%=*}
  value=${line#*=}
  if [[ "$key" == "$line" ]]; then
    value=""
  fi

  # Write exact value (no trailing newline added)
  printf '%s' "$value" > "$OUTDIR/$key"
done < <(get_env_lines)

echo "Wrote env files to: $OUTDIR"
