#!/bin/sh

set -e

SCRIPT_DIR=$(dirname "$0")

# Provide visibility into which version of the bootstrapping package ran
cat "${SCRIPT_DIR}/rwx-package.yml" | awk 'NF == 0 { exit } { print }'
echo ""

# The image is pulled and unpacked without a container runtime, so the base layer
# this runs on provides crane, jq and tar rather than dockerd. The docker CLI
# cannot stand in for crane here: it is only an Engine API client, so pull,
# create and export all require a reachable daemon.
for tool in crane jq tar; do
  if ! command -v "$tool" > /dev/null 2>&1; then
    echo "Error: \`${tool}\` is required to bootstrap a base image but is not in PATH." >&2
    exit 1
  fi
done

# crane defaults to linux/amd64 wherever it runs, unlike `docker pull`, which
# uses the daemon's native platform. Selecting explicitly keeps arm64 agents from
# extracting an amd64 rootfs.
case "$(uname -m)" in
  x86_64) PLATFORM="linux/amd64" ;;
  aarch64 | arm64) PLATFORM="linux/arm64" ;;
  *) echo "Error: unsupported architecture $(uname -m)" >&2; exit 1 ;;
esac

# Kept out of the workspace so it does not land in the task's output filesystem.
IMAGE_CONFIG=$(mktemp)
trap 'rm -f "${IMAGE_CONFIG}"' EXIT

mkdir image
crane export --platform "${PLATFORM}" "${IMAGE}" - | tar -x -C image -f - -p

# The image config carries the env, entrypoint and command. Its digest is the
# image ID that `docker container inspect` reported as `.Image`.
crane config --platform "${PLATFORM}" "${IMAGE}" > "${IMAGE_CONFIG}"
imageId=$(crane manifest --platform "${PLATFORM}" "${IMAGE}" | jq -r ".config.digest")

printf '%s\n' root | tee ${RWX_IMAGE}/user

if [ -f image/etc/os-release ]; then
  . image/etc/os-release
  printf '%s\n' "${ID} ${VERSION_ID}" | tee ${RWX_IMAGE}/os
else
  printf '%s\n' "${IMAGE} ${imageId}" | tee ${RWX_IMAGE}/os
fi

if [ -f image/bin/bash ]; then
  printf '%s\n' "/bin/bash -l -e -o pipefail" | tee ${RWX_IMAGE}/shell
else
  printf '%s\n' "/bin/sh -l -e" | tee ${RWX_IMAGE}/shell
fi

${SCRIPT_DIR}/extract-env.sh "${IMAGE_CONFIG}" ${RWX_ENV}

jq -c ".config.Entrypoint" "${IMAGE_CONFIG}" | tee "$RWX_IMAGE/entrypoint.json"
jq -c ".config.Cmd" "${IMAGE_CONFIG}" | tee "$RWX_IMAGE/command.json"

printf '%s\n' "${imageId}" | tee ${RWX_VALUES}/image-sha
printf '%s\n' "${IMAGE}" | tee ${RWX_VALUES}/image-name
