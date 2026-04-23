#!/usr/bin/env bash

set -euo pipefail

source "${RWX_PACKAGE_PATH}/scripts/mint-utils.sh"

echo 'tzdata tzdata/Areas select Etc'       | debconf-set-selections
echo 'tzdata tzdata/Zones/Etc select UTC'   | debconf-set-selections

# On 22.04+ the BSD-derived utilities (rev, column, hexdump, look, ul, ...)
# were split out of util-linux into a separate bsdextrautils package. On
# 20.04 focal those utilities still live in util-linux and bsdextrautils is
# not a published package.
packages=(
  build-essential
  ca-certificates
  curl
  dtach
  git
  gnupg
  jq
  sudo
  tzdata
  unzip
  wget
  xz-utils
)
if mint_os_version_gte 22.04; then
  packages+=(bsdextrautils)
fi

apt-get update
apt-get upgrade -y
apt-get install -y "${packages[@]}"
apt-get clean
rm -rf /var/lib/apt/lists/*
