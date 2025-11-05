#!/usr/bin/env bash

set -euo pipefail

# https://manpages.debian.org/bullseye/debconf-doc/debconf.7.en.html#Frontends
# > This is the anti-frontend. It never interacts with you at all, and
# > makes the default answers be used for all questions. It might mail
# > error messages to root, but that's it; otherwise it is completely
# > silent and unobtrusive, a perfect frontend for automatic installs.
# > ...
# Set for sessions that call pam_env with readenv=1; for example, sudo.
echo 'DEBIAN_FRONTEND=noninteractive' | tee -a /etc/environment
# Set for all login shells
echo 'export DEBIAN_FRONTEND=noninteractive' > /etc/profile.d/02-debian-frontend.sh

# Configure dpkg to not ask questions about config files it is upgrading.
# Upgrade configurations if there are no local modifications; otherwise, keep the local version.
# - --force-confdef: Use the default action for new versions of configuration files.
#   If the package's configuration file has been changed since the last install, use the maintainer's version, otherwise, keep the local version.
# - --force-confold: Always keep locally modified configuration files, even when there is a new version provided by the package.
#   This takes precedence over --force-confdef when both are used together, ensuring that the current local configurations are maintained during an upgrade.
# https://manpages.debian.org/buster/dpkg/dpkg.1#OPTIONS
# See also https://github.com/actions/runner-images/commit/f2df3a55d
cat <<EOF >> /etc/apt/apt.conf.d/90-dpkg-force-conf
Dpkg::Options {
  "--force-confdef";
  "--force-confold";
}
EOF

# https://manpages.ubuntu.com/manpages/jammy/man8/apt-get.8.html
cat <<EOF >> /etc/apt/apt.conf.d/91-apt-get-assume-yes
APT::Get::Assume-Yes "true";
EOF

echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

mkdir -p /var/mint-workspace
chown -R ubuntu:ubuntu /var/mint-workspace

# Don't write .sudo_as_admin_successful on first use of `sudo`
cat <<EOF >> /etc/sudoers.d/disable_admin_file_in_home
Defaults !admin_flag
EOF

# Ensure /etc/timezone is valid
sudo dpkg-reconfigure tzdata

# Disable login message when using SSH
touch /home/ubuntu/.hushlogin

# this runs clear_console which does not work (and causes logouts from the shell where we run commands
# to always exit with 1- e.g. if you call exit 0 in your `run` script)
# more info: https://www.reddit.com/r/linuxadmin/comments/hehpf7/bash_logout_fails_to_run_on_ubuntu_1804_lts/
rm /home/ubuntu/.bash_logout
