#!/usr/bin/env bash

set -euo pipefail

source "${RWX_PACKAGE_PATH}/scripts/mint-utils.sh"

echo "Installing Docker on $(mint_os_name_version)"

case "$(mint_os_name_version)" in
  "ubuntu 26.04")
    DOCKER_VERSION=5:29.4.1-1~ubuntu.26.04~resolute
    DOCKER_BUILDX_VERSION=0.33.0-1~ubuntu.26.04~resolute
    DOCKER_COMPOSE_VERSION=5.1.3-1~ubuntu.26.04~resolute
    CONTAINERD_IO_VERSION=2.2.3-1~ubuntu.26.04~resolute
    ;;
  "ubuntu 24.04")
    DOCKER_VERSION=5:28.0.4-1~ubuntu.24.04~noble
    DOCKER_BUILDX_VERSION=0.22.0-1~ubuntu.24.04~noble
    DOCKER_COMPOSE_VERSION=2.34.0-1~ubuntu.24.04~noble
    CONTAINERD_IO_VERSION=1.7.26-1
    ;;
  "ubuntu 22.04")
    DOCKER_VERSION=5:26.0.1-1~ubuntu.22.04~jammy
    DOCKER_BUILDX_VERSION=0.17.1-1~ubuntu.22.04~jammy
    DOCKER_COMPOSE_VERSION=2.29.7-1~ubuntu.22.04~jammy
    CONTAINERD_IO_VERSION=1.7.23-1
    ;;
  "ubuntu 20.04")
    DOCKER_VERSION=5:28.1.1-1~ubuntu.20.04~focal
    DOCKER_BUILDX_VERSION=0.23.0-1~ubuntu.20.04~focal
    DOCKER_COMPOSE_VERSION=2.35.1-1~ubuntu.20.04~focal
    CONTAINERD_IO_VERSION=1.7.27-1
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
  containerd.io=$CONTAINERD_IO_VERSION \
  docker-buildx-plugin=$DOCKER_BUILDX_VERSION \
  docker-compose-plugin=$DOCKER_COMPOSE_VERSION
apt-get clean
rm -rf /var/lib/apt/lists/*

# Docker 29.x enables the containerd image store by default. Disable it so we
# keep using the classic overlay2 snapshotter, matching older Ubuntu versions
# that ship with Docker 26.x/28.x.
if [ "$(mint_os_name_version)" = "ubuntu 26.04" ]; then
  install -m 0755 -d /etc/docker
  cat > /etc/docker/daemon.json <<'EOF'
{
  "features": {
    "containerd-snapshotter": false
  }
}
EOF
fi

usermod -aG docker ubuntu
