#!/bin/sh

set -e

SCRIPT_DIR=$(dirname "$0")

# Provide visibility into which version of the bootstrapping package ran
cat "${SCRIPT_DIR}/rwx-package.yml" | awk 'NF == 0 { exit } { print }'
echo ""

mkdir image
docker pull ${IMAGE}
containerId=$(docker create ${IMAGE})
docker export "$containerId" | sudo tar -x -C image -f - -p

echo root | tee ${RWX_IMAGE}/user

if [ -f image/bin/bash ]; then
  echo "/bin/bash -l -e -o pipefail" | tee ${RWX_IMAGE}/shell
else
  echo "/bin/sh -l -e" | tee ${RWX_IMAGE}/shell
fi

${SCRIPT_DIR}/extract-env.sh "$containerId" ${RWX_ENV}

docker container inspect "$containerId" | jq -r ".[0].Image" | tee ${RWX_VALUES}/image-sha
docker container inspect "$containerId" | jq -r ".[0].Config.Image" | tee ${RWX_VALUES}/image-name
