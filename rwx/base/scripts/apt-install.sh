#!/usr/bin/env bash

set -euo pipefail

source "${RWX_PACKAGE_PATH}/scripts/rwx-utils.sh"

echo 'tzdata tzdata/Areas select Etc'       | debconf-set-selections
echo 'tzdata tzdata/Zones/Etc select UTC'   | debconf-set-selections

# On Ubuntu 22.04+ and Debian (all currently supported releases) the
# BSD-derived utilities (rev, column, hexdump, look, ul, ...) were split out
# of util-linux into a separate bsdextrautils package. On Ubuntu 20.04 focal
# those utilities still live in util-linux and bsdextrautils is not a
# published package.
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
if [ "$(rwx_os_name)" = "debian" ] || rwx_os_version_gte 22.04; then
  packages+=(bsdextrautils)
fi

apt-get update
apt-get upgrade -y
apt-get install -y "${packages[@]}"
apt-get clean
rm -rf /var/lib/apt/lists/*
