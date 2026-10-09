#!/usr/bin/env bash

set -ueo pipefail

pushd build

go test ./...

for arch in amd64 arm64; do
  echo "Building the mtime binary for $arch"
  CGO_ENABLED=0 GOOS=linux GOARCH=$arch go build -o "../bin/git-restore-mtime-$arch" .
done

popd

echo "Removing the build directory"
rm -rf build
