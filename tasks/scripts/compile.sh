#!/bin/bash

set -euo pipefail

output="$(pwd)/compiled/"

cd repo
[ ! -z "$CONTEXT" ] && cd "$CONTEXT"
CGO_ENABLED=0 go build -o "$output" "$PACKAGE_PATH"
