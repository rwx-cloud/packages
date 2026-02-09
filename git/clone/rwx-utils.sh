#!/bin/sh
# rwx-utils version 2.0.1

detected_os=""
detected_os_version=""
detected_os_codename=""
detected_arch=""
detected_package_manager=""

rwx__detect_os_arch() {
  if [ -f /etc/os-release ]; then
    . /etc/os-release

    detected_os="$ID"
    detected_os_version="$VERSION_ID"
    detected_os_codename="$VERSION_CODENAME"

    case "$ID" in
      ubuntu|debian)
        detected_package_manager="apt"
        ;;
      alpine)
        detected_package_manager="apk"
        ;;
    esac
  fi

  detected_arch=$(uname -m)
}

rwx_os_name() {
  if [ -z "$detected_os" ]; then
    rwx__detect_os_arch
  fi
  printf '%s\n' "$detected_os"
}

rwx_os_version() {
  if [ -z "$detected_os_version" ]; then
    rwx__detect_os_arch
  fi
  printf '%s\n' "$detected_os_version"
}

# Output the name and version of the operating system as expected by RWX's `base.os` field.
rwx_os_name_version() {
  printf '%s %s\n' "$(rwx_os_name)" "$(rwx_os_version)"
}

rwx_os_codename() {
  if [ -z "$detected_os_codename" ]; then
    rwx__detect_os_arch
  fi
  printf '%s\n' "$detected_os_codename"
}

rwx_arch() {
  if [ -z "$detected_arch" ]; then
    rwx__detect_os_arch
  fi
  printf '%s\n' "$detected_arch"
}

rwx_arch_amd() {
  arch="$(rwx_arch)"
  if [ "$arch" = "x86_64" ]; then
    printf '%s\n' "amd64"
  else
    printf '%s\n' "$arch"
  fi
}

rwx_os_package_manager() {
  if [ -z "$detected_package_manager" ]; then
    rwx__detect_os_arch
  fi
  printf '%s\n' "$detected_package_manager"
}

rwx_os_version_gte() {
  compare_version="$1"
  printf '%s\n' "$compare_version" "$(rwx_os_version)" | sed 's/\([0-9.]*\).*/\1/' | sort -c -t. -k1,1n -k2,2n -k3,3n >/dev/null 2>&1
}

rwx_os_version_lte() {
  compare_version="$1"
  printf '%s\n' "$compare_version" "$(rwx_os_version)" | sed 's/\([0-9.]*\).*/\1/' | sort -c -t. -k1,1n -k2,2n -k3,3n -r >/dev/null 2>&1
}

# Convert a string something usable as a RWX key.
#
# Replaces all non-alphanumeric characters with hyphens, compressing multiple hyphens into one.
rwx_keyify() {
  printf '%s' "$*" | tr -c -s '[:alnum:]' '-'
}

# Check if the provided list contains a given element.
#
# Usage: rwx_contains two one two three
rwx_contains() {
  if [ "$#" -eq 0 ]; then
    return 1
  fi

  needle=$1
  shift

  for item do
    if [ "$item" = "$needle" ]; then
      return 0
    fi
  done

  return 1
}

rwx_os_name_in() {
  rwx_contains "$(rwx_os_name)" "$@"
}

rwx_os_package_manager_in() {
  rwx_contains "$(rwx_os_package_manager)" "$@"
}

rwx_maybe_sudo() {
  if [ "$(id -u)" -eq 0 ]; then
    "$@"
  else
    # If sudo is available, use it
    if command -v sudo >/dev/null 2>&1; then
      sudo "$@"
    else
      echo "Error: need root privileges but 'sudo' not found" >&2
      return 1
    fi
  fi
}
