#!/usr/bin/env bash

set -euo pipefail

source "${RWX_PACKAGE_PATH}/scripts/rwx-utils.sh"

# We write apt sources in deb822 format and blank out /etc/apt/sources.list so
# apt only reads our new file (otherwise apt would see the same logical
# targets in both files, produce "configured multiple times" warnings, and
# sometimes prefer the public mirror over our chosen primary).
#
# We use HTTP (not HTTPS) so this script can run on a fresh image before
# ca-certificates is installed. Package integrity is still verified via GPG
# signatures regardless of transport.

. /etc/os-release
codename="$VERSION_CODENAME"
arch="$(dpkg --print-architecture)"

case "$(rwx_os_name)" in
  ubuntu)
    case "$arch" in
      amd64|i386)
        mirrors=(
          us-east-2.ec2.archive.ubuntu.com/ubuntu
          us-east-1.ec2.archive.ubuntu.com/ubuntu
          azure.archive.ubuntu.com/ubuntu
          archive.ubuntu.com/ubuntu
        )
        ;;
      *)
        mirrors=(
          us-east-2.ec2.ports.ubuntu.com/ubuntu-ports
          us-east-1.ec2.ports.ubuntu.com/ubuntu-ports
          ports.ubuntu.com/ubuntu-ports
        )
        ;;
    esac

    : > /etc/apt/ubuntu-mirrors.txt
    for i in "${!mirrors[@]}"; do
      printf 'http://%s/\tpriority:%d\n' "${mirrors[$i]}" "$((i + 1))" >> /etc/apt/ubuntu-mirrors.txt
    done

    # Fail over from a stalled mirror sooner than apt's 120s default.
    mkdir -p /etc/apt/apt.conf.d
    cat > /etc/apt/apt.conf.d/80rwx-mirror-failover <<EOF
Acquire::http::Timeout "10";
Acquire::Retries "2";
EOF

    mkdir -p /etc/apt/sources.list.d
    cat > /etc/apt/sources.list.d/ubuntu.sources <<EOF
Types: deb
URIs: mirror+file:/etc/apt/ubuntu-mirrors.txt
Suites: ${codename} ${codename}-updates ${codename}-backports
Components: main universe restricted multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg
EOF
    ;;

  debian)
    # Use Debian's default mirror (deb.debian.org, fronted by Fastly).
    mkdir -p /etc/apt/sources.list.d
    cat > /etc/apt/sources.list.d/debian.sources <<EOF
Types: deb
URIs: http://deb.debian.org/debian
Suites: ${codename} ${codename}-updates
Components: main
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg

Types: deb
URIs: http://deb.debian.org/debian-security
Suites: ${codename}-security
Components: main
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
EOF
    ;;
esac

if [ -f /etc/apt/sources.list ]; then
  : > /etc/apt/sources.list
fi
