#!/usr/bin/env bash

set -ueo pipefail

mkdir bin
pushd build

echo "Building the patterns binary for amd64"
GOOS=linux GOARCH=amd64 go build -o ../bin/glob_patterns-amd64 ./glob_patterns.go

echo "Building the patterns binary for arm64"
GOOS=linux GOARCH=arm64 go build -o ../bin/glob_patterns-arm64 ./glob_patterns.go

popd

echo "Removing the build directory"
rm -rf build
