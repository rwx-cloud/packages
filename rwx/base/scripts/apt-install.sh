#!/usr/bin/env bash

set -euo pipefail

echo 'tzdata tzdata/Areas select Etc'       | debconf-set-selections
echo 'tzdata tzdata/Zones/Etc select UTC'   | debconf-set-selections

apt-get update
apt-get upgrade -y
apt-get install -y \
  build-essential \
  ca-certificates \
  curl \
  dtach \
  git \
  gnupg \
  jq \
  sudo \
  tzdata \
  unzip \
  wget \
  xz-utils
apt-get clean
rm -rf /var/lib/apt/lists/*
