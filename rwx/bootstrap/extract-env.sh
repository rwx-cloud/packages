#!/bin/sh

set -eu

usage() {
  echo "Usage: $0 <container> <output_dir>"
  echo "Example: $0 my-running-container ./env_out"
  exit 1
}

if [ "$#" -ne 2 ]; then
  usage
fi

CONTAINER=$1
OUTDIR=$2

if ! command -v docker >/dev/null 2>&1; then
  echo "Error: docker is not installed or not in PATH." >&2
  exit 2
fi

if ! docker container inspect "$CONTAINER" >/dev/null 2>&1; then
  echo "Error: container '$CONTAINER' not found." >&2
  exit 2
fi

# Read env lines from the container's Config.Env (initial env at container start)
get_env_lines() {
  if docker container inspect --format '{{range .Config.Env}}{{println .}}{{end}}' "$CONTAINER"; then
    return 0
  else
    echo "Error: Failed to read env from container." >&2
    return 1
  fi
}

get_env_lines | while IFS= read -r line; do
  if [ -z "$line" ]; then
    continue
  fi

  echo "$line"

  # Split on first '=' only (POSIX parameter expansion is fine)
  key=${line%%=*}
  value=${line#*=}

  # If there was no '=', value should be empty
  if [ "$key" = "$line" ]; then
    value=""
  fi

  # (Optional hardening) skip empty keys
  if [ -z "$key" ]; then
    continue
  fi

  printf '%s' "$value" > "$OUTDIR/$key"
done

echo "Wrote env files to: $OUTDIR"
