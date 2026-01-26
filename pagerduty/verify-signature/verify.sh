#!/bin/sh
set -eu

# Usage check
if [ $# -lt 3 ]; then
  echo "Usage: verify.sh <shared-secret> <provided-signatures> <version-prefix>" >&2
  exit 1
fi

key="$1"
signatures="$2"
version="$3"

# Read payload from stdin
payload=$(cat)

# Compute HMAC-SHA256
computed_signature=$(printf '%s' "$payload" | openssl dgst -sha256 -hmac "$key" | awk '{print $2}')

# Add version prefix
signature_with_version="${version}=${computed_signature}"

# Split signatures by comma and check each one
old_ifs="$IFS"
IFS=','
for sig in $signatures; do
  # Trim whitespace
  sig=$(echo "$sig" | xargs)

  if [ "$signature_with_version" = "$sig" ]; then
    echo "Signature verified"
    IFS="$old_ifs"
    exit 0
  fi
done
IFS="$old_ifs"

echo "Signature verification failed" >&2
exit 1
