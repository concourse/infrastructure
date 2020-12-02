#!/bin/bash

set -euo pipefail

output="$(pwd)/compiled/"

cd repo
[ ! -z "$CONTEXT" ] && cd "$CONTEXT"
go build -o "$output" "$PACKAGE_PATH"
