#!/usr/bin/env bash

# Do not let inherited credentials override the token supplied to this package.
unset GH_TOKEN GITHUB_TOKEN GH_ENTERPRISE_TOKEN GITHUB_ENTERPRISE_TOKEN
case "$GH_HOST" in
  github.com|*.ghe.com)
    export GH_TOKEN="$PACKAGE_GITHUB_TOKEN"
    ;;
  *)
    export GH_ENTERPRISE_TOKEN="$PACKAGE_GITHUB_TOKEN"
    ;;
esac
