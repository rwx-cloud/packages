#!/bin/sh

set -eu

usage() {
  echo "Usage: $0 <image_config_json> <output_dir>"
  echo "Example: $0 ./image-config.json ./env_out"
  exit 1
}

if [ "$#" -ne 2 ]; then
  usage
fi

IMAGE_CONFIG=$1
OUTDIR=$2

if ! command -v jq >/dev/null 2>&1; then
  echo "Error: jq is not installed or not in PATH." >&2
  exit 2
fi

if [ ! -f "$IMAGE_CONFIG" ]; then
  echo "Error: image config '$IMAGE_CONFIG' not found." >&2
  exit 2
fi

# Read env lines from the image's Config.Env (initial env at container start)
get_env_lines() {
  if jq -r '.config.Env // [] | .[]' "$IMAGE_CONFIG"; then
    return 0
  else
    echo "Error: Failed to read env from image config." >&2
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
