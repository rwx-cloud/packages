#!/usr/bin/env bash

set -euo pipefail

# Point apt at the AWS EC2 regional mirror for faster access and higher uptime,
# with the public Ubuntu archive as a fallback URI in the same stanza so apt
# transparently fails over on AWS-side outages.
#
# We write /etc/apt/sources.list.d/ubuntu.sources in deb822 format. On 24.04
# this overwrites the default. On 20.04/22.04 the default sources live in
# /etc/apt/sources.list — we blank that file out so apt only reads our new
# file (otherwise apt would see the same logical targets in both files,
# produce "configured multiple times" warnings, and sometimes prefer the
# public mirror over the AWS primary).
#
# Two-pass: first over HTTP so apt can install ca-certificates on a fresh
# image (HTTPS would fail without ca-certificates), then rewrite to the final
# scheme. The ports mirror (arm64 etc.) doesn't support HTTPS, so it stays on
# HTTP for both passes; the archive mirror (amd64/i386) upgrades to HTTPS
# after ca-certificates is installed.
aws_apt_mirror_region="us-east-2"

. /etc/os-release
codename="$VERSION_CODENAME"
arch="$(dpkg --print-architecture)"

case "$arch" in
  amd64|i386)
    primary_mirror="${aws_apt_mirror_region}.ec2.archive.ubuntu.com/ubuntu"
    fallback_mirror="archive.ubuntu.com/ubuntu"
    final_scheme="https"
    ;;
  *)
    primary_mirror="${aws_apt_mirror_region}.ec2.ports.ubuntu.com/ubuntu-ports"
    fallback_mirror="ports.ubuntu.com/ubuntu-ports"
    final_scheme="http"
    ;;
esac

write_sources() {
  local scheme="$1"
  mkdir -p /etc/apt/sources.list.d
  cat > /etc/apt/sources.list.d/ubuntu.sources <<EOF
Types: deb
URIs: ${scheme}://${primary_mirror}/ ${scheme}://${fallback_mirror}/
Suites: ${codename} ${codename}-updates ${codename}-backports ${codename}-security
Components: main universe restricted multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg
EOF
}

if [ -f /etc/apt/sources.list ]; then
  : > /etc/apt/sources.list
fi

write_sources http

apt-get update
apt-get install -y ca-certificates

write_sources "$final_scheme"
