#!/usr/bin/env bash

set -euo pipefail

source "${RWX_PACKAGE_PATH}/scripts/mint-utils.sh"

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

case "$(mint_os_name)" in
  ubuntu)
    # Point apt at the AWS EC2 regional mirror for the archive and at
    # security.ubuntu.com (or ports.ubuntu.com on non-primary arches) for
    # security updates. This matches the default sources shipped on
    # Canonical's EC2 AMIs.
    aws_apt_mirror_region="us-east-2"

    case "$arch" in
      amd64|i386)
        archive_mirror="${aws_apt_mirror_region}.ec2.archive.ubuntu.com/ubuntu"
        security_mirror="security.ubuntu.com/ubuntu"
        ;;
      *)
        archive_mirror="${aws_apt_mirror_region}.ec2.ports.ubuntu.com/ubuntu-ports"
        security_mirror="ports.ubuntu.com/ubuntu-ports"
        ;;
    esac

    mkdir -p /etc/apt/sources.list.d
    cat > /etc/apt/sources.list.d/ubuntu.sources <<EOF
Types: deb
URIs: http://${archive_mirror}/
Suites: ${codename} ${codename}-updates ${codename}-backports
Components: main universe restricted multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg

Types: deb
URIs: http://${security_mirror}/
Suites: ${codename}-security
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
