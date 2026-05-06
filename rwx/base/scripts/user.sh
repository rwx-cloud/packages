#!/usr/bin/env bash

set -euo pipefail

if id -u 1000 &>/dev/null; then
  existing_user=$(id -un 1000)
  echo "uid 1000 already exists ($existing_user); leaving it as-is"
  usermod -aG sudo $existing_user
else
  groupadd --gid 1000 rwx
  useradd --uid 1000 --no-log-init --system --gid rwx --create-home --home-dir /home/rwx rwx
  usermod -aG sudo rwx
fi
