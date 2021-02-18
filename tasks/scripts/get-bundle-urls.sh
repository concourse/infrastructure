#!/bin/bash

set -euo pipefail

pushd concourse-release > /dev/null
  tag="$(cat tag)"
  darwin=$(printf concourse-*-darwin-amd64.tgz)
  windows=$(printf concourse-*-windows-amd64.zip)
popd > /dev/null

base_url="https://github.com/concourse/concourse/releases/download/$tag"

echo "$base_url/$darwin" > bundle-urls/darwin
echo "$base_url/$windows" > bundle-urls/windows
