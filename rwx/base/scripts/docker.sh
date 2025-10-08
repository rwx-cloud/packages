#!/usr/bin/env bash

set -euo pipefail

source "${RWX_PACKAGE_PATH}/scripts/mint-utils.sh"

echo "Installing Docker on $(mint_os_name_version)"

case "$(mint_os_name_version)" in
  "ubuntu 24.04")
    DOCKER_VERSION=5:28.0.4-1~ubuntu.24.04~noble
    DOCKER_BUILDX_VERSION=0.22.0-1~ubuntu.24.04~noble
    DOCKER_COMPOSE_VERSION=2.34.0-1~ubuntu.24.04~noble
    ;;
  "ubuntu 22.04")
    DOCKER_VERSION=5:28.5.1-1~ubuntu.22.04~jammy
    DOCKER_BUILDX_VERSION=0.29.1-1~ubuntu.22.04~jammy
    DOCKER_COMPOSE_VERSION=2.40.0-1~ubuntu.22.04~jammy
    ;;
  "ubuntu 20.04")
    DOCKER_VERSION=5:28.1.1-1~ubuntu.20.04~focal
    DOCKER_BUILDX_VERSION=0.23.0-1~ubuntu.20.04~focal
    DOCKER_COMPOSE_VERSION=2.35.1-1~ubuntu.20.04~focal
    ;;
  *)
    echo "Operating system not supported"
    exit 1
    ;;
esac


install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" > /etc/apt/sources.list.d/docker.list
apt-get update
apt-get install -y \
  docker-ce=$DOCKER_VERSION \
  docker-ce-cli=$DOCKER_VERSION \
  docker-ce-rootless-extras=$DOCKER_VERSION \
  containerd.io=1.7.26-1 \
  docker-buildx-plugin=$DOCKER_BUILDX_VERSION \
  docker-compose-plugin=$DOCKER_COMPOSE_VERSION
apt-get clean
rm -rf /var/lib/apt/lists/*

usermod -aG docker ubuntu
