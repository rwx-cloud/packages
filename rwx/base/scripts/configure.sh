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

uid_1000_user="$(id -un 1000)"
uid_1000_home="$(getent passwd 1000 | cut -d: -f6)"

mkdir -p /var/mint-workspace
chown -R "$uid_1000_user:$uid_1000_user" /var/mint-workspace
echo /var/mint-workspace > $RWX_IMAGE/workspace

# Don't write .sudo_as_admin_successful on first use of `sudo`.
# The `admin_flag` sudoers setting is an Ubuntu patch to classic `sudo`,
# carried by Ubuntu 22.04–25.04 and by Debian 12+. Older releases ship an
# unpatched classic sudo that errors on the directive (Ubuntu 20.04's
# 1.8.31, Debian 11's 1.9.5), and Ubuntu 25.10+ defaults to `sudo-rs` which
# also doesn't recognize it (and doesn't emit ~/.sudo_as_admin_successful in
# the first place, so the directive isn't needed there).
source "${RWX_PACKAGE_PATH}/scripts/rwx-utils.sh"
admin_flag_supported=false
case "$(rwx_os_name)" in
  ubuntu)
    if rwx_os_version_gte 22.04 && rwx_os_version_lte 25.04; then
      admin_flag_supported=true
    fi
    ;;
  debian)
    if rwx_os_version_gte 12; then
      admin_flag_supported=true
    fi
    ;;
esac
if $admin_flag_supported; then
  cat <<EOF >> /etc/sudoers.d/disable_admin_file_in_home
Defaults !admin_flag
EOF
fi

# Debian's /etc/profile resets $PATH to a hardcoded list, which clobbers the
# entries RWX prepends (e.g. for installed languages and tools) when a login
# shell sources it. Rewrite the assignments so they preserve any existing
# $PATH instead of overwriting it. Ubuntu's /etc/profile does not touch PATH.
if [ "$(rwx_os_name)" = "debian" ]; then
  sed -i '/^[[:space:]]*PATH="/ s/PATH="/PATH="$PATH:/' /etc/profile
fi

# Ensure /etc/timezone is valid
sudo dpkg-reconfigure tzdata

# Disable login message when using SSH
touch "$uid_1000_home/.hushlogin"

# this runs clear_console which does not work (and causes logouts from the shell where we run commands
# to always exit with 1- e.g. if you call exit 0 in your `run` script)
# more info: https://www.reddit.com/r/linuxadmin/comments/hehpf7/bash_logout_fails_to_run_on_ubuntu_1804_lts/
rm -f "$uid_1000_home/.bash_logout"
