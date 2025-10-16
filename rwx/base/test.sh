#!/usr/bin/env bash

set -euo pipefail

export RWX_ACCESS_TOKEN=$(cat ~/.config/rwx/accesstoken)

(cd rwx/base && zip -X -r /tmp/rwx-base-package.zip .)

curl \
  --request POST \
  --fail-with-body \
  --header "Authorization: Bearer $RWX_ACCESS_TOKEN" \
  --header 'Accept: application/json' \
  -F 'file=@/tmp/rwx-base-package.zip' \
  https://cloud.rwx.com/mint/api/leaves
