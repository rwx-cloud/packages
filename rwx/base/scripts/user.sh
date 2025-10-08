#!/usr/bin/env bash

set -euo pipefail

if id "ubuntu" &>/dev/null; then
  echo "ubuntu user already exists"
else
  groupadd --gid 1000 ubuntu
  useradd --uid 1000 --no-log-init --system --gid ubuntu --create-home --home-dir /home/ubuntu ubuntu
  usermod -aG sudo ubuntu
fi
